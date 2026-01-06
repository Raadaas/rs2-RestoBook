using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using eCommerce.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    public class ReservationService : BaseCRUDService<ReservationResponse, ReservationSearchObject, Database.Reservation, ReservationUpsertRequest, ReservationUpsertRequest>, IReservationService
    {
        public ReservationService(eCommerceDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override async Task BeforeInsert(Database.Reservation entity, ReservationUpsertRequest request)
        {
            // Validate user exists and is active
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == entity.UserId);
            if (user == null)
            {
                throw new InvalidOperationException($"User with ID {entity.UserId} does not exist.");
            }
            if (!user.IsActive)
            {
                throw new InvalidOperationException($"User is not active.");
            }

            // Load restaurant to check working hours
            var restaurant = await _context.Restaurants
                .FirstOrDefaultAsync(r => r.Id == entity.RestaurantId);

            if (restaurant == null)
            {
                throw new InvalidOperationException($"Restaurant with ID {entity.RestaurantId} does not exist.");
            }

            if (!restaurant.IsActive)
            {
                throw new InvalidOperationException($"Restaurant is not active.");
            }

            // Validate table exists and is active
            var table = await _context.Tables
                .FirstOrDefaultAsync(t => t.Id == entity.TableId && t.RestaurantId == entity.RestaurantId);

            if (table == null)
            {
                throw new InvalidOperationException($"Table with ID {entity.TableId} does not exist in restaurant {entity.RestaurantId}.");
            }

            if (!table.IsActive)
            {
                throw new InvalidOperationException($"Table {table.TableNumber} is not active.");
            }

            // Validate number of guests fits table capacity
            if (entity.NumberOfGuests <= 0)
            {
                throw new InvalidOperationException("Number of guests must be greater than zero.");
            }

            if (entity.NumberOfGuests > table.Capacity)
            {
                throw new InvalidOperationException(
                    $"Number of guests ({entity.NumberOfGuests}) exceeds table capacity ({table.Capacity}).");
            }

            // Validate duration is positive
            if (entity.Duration <= TimeSpan.Zero)
            {
                throw new InvalidOperationException("Reservation duration must be greater than zero.");
            }

            // Validate reservation date is not in the past
            var now = DateTime.UtcNow;
            var reservationStart = entity.ReservationDate.Date.Add(entity.ReservationTime);
            
            if (reservationStart < now)
            {
                throw new InvalidOperationException(
                    $"Reservation time {reservationStart:yyyy-MM-dd HH:mm} is in the past. Please select a future date and time.");
            }

            // Calculate end time
            var reservationEnd = reservationStart.Add(entity.Duration);

            // 1. Validate working hours
            // Handle case where close time is next day (e.g., 22:00 to 02:00)
            var restaurantOpenTime = entity.ReservationDate.Date.Add(restaurant.OpenTime);
            var restaurantCloseTime = entity.ReservationDate.Date.Add(restaurant.CloseTime);

            if (restaurant.CloseTime < restaurant.OpenTime)
            {
                // Restaurant closes next day (e.g., opens at 10:00, closes at 02:00 next day)
                restaurantCloseTime = restaurantCloseTime.AddDays(1);
                
                // If reservation spans midnight, check both days
                if (reservationEnd.Date > reservationStart.Date)
                {
                    // Reservation spans midnight - check if it's within working hours
                    // For example: restaurant 22:00-02:00, reservation 23:00-01:00 is OK
                    if (reservationStart < restaurantOpenTime || reservationEnd > restaurantCloseTime)
                    {
                        throw new InvalidOperationException(
                            $"Reservation time {reservationStart:HH:mm} - {reservationEnd:HH:mm} is outside restaurant working hours {restaurant.OpenTime:hh\\:mm} - {restaurant.CloseTime:hh\\:mm}.");
                    }
                }
                else
                {
                    // Reservation doesn't span midnight
                    // Check if reservation is before closing time of previous day or after opening time
                    var previousDayClose = restaurantCloseTime.AddDays(-1);
                    if (reservationStart < restaurantOpenTime && reservationEnd <= previousDayClose)
                    {
                        throw new InvalidOperationException(
                            $"Reservation time {reservationStart:HH:mm} - {reservationEnd:HH:mm} is outside restaurant working hours {restaurant.OpenTime:hh\\:mm} - {restaurant.CloseTime:hh\\:mm}.");
                    }
                }
            }
            else
            {
                // Normal case: restaurant closes same day
                if (reservationStart < restaurantOpenTime || reservationEnd > restaurantCloseTime)
                {
                    throw new InvalidOperationException(
                        $"Reservation time {reservationStart:HH:mm} - {reservationEnd:HH:mm} is outside restaurant working hours {restaurant.OpenTime:hh\\:mm} - {restaurant.CloseTime:hh\\:mm}.");
                }
            }

            // 2. Check if user has overlapping reservations in different restaurants
            // NOTE: User CAN have multiple overlapping reservations in the SAME restaurant (different tables)
            // User CANNOT have overlapping reservations in DIFFERENT restaurants
            // Only check active reservations (not cancelled and not yet completed)
            var reservationEndDate = reservationEnd.Date;
            
            var userOverlappingReservations = await _context.Reservations
                .Where(r => r.UserId == entity.UserId
                    && r.RestaurantId != entity.RestaurantId  // Only check different restaurants
                    && r.Status != "Cancelled"
                    && r.CancelledAt == null
                    && (r.ReservationDate.Date == entity.ReservationDate.Date || r.ReservationDate.Date == reservationEndDate))
                .ToListAsync();

            foreach (var existingReservation in userOverlappingReservations)
            {
                var existingStart = existingReservation.ReservationDate.Date.Add(existingReservation.ReservationTime);
                var existingEnd = existingStart.Add(existingReservation.Duration);

                // Only check if existing reservation is still active (not completed)
                // Table release: if reservation has ended, it's no longer blocking
                if (existingEnd <= now)
                {
                    continue; // This reservation has ended, table is free
                }

                // Check overlap using half-open interval: [start, end)
                // Overlap exists if: start1 < end2 AND start2 < end1
                if (reservationStart < existingEnd && existingStart < reservationEnd)
                {
                    throw new InvalidOperationException(
                        $"User already has a reservation at {existingStart:HH:mm} - {existingEnd:HH:mm} in another restaurant. Cannot have overlapping reservations in different restaurants.");
                }
            }

            // 3. Check if table has overlapping reservations
            // Only check active reservations (not cancelled and not yet completed)
            var tableOverlappingReservations = await _context.Reservations
                .Where(r => r.TableId == entity.TableId
                    && r.RestaurantId == entity.RestaurantId
                    && r.Status != "Cancelled"
                    && r.CancelledAt == null
                    && (r.ReservationDate.Date == entity.ReservationDate.Date || r.ReservationDate.Date == reservationEndDate))
                .ToListAsync();

            foreach (var existingReservation in tableOverlappingReservations)
            {
                var existingStart = existingReservation.ReservationDate.Date.Add(existingReservation.ReservationTime);
                var existingEnd = existingStart.Add(existingReservation.Duration);

                // Table release: if reservation has ended, it's no longer blocking
                if (existingEnd <= now)
                {
                    continue; // This reservation has ended, table is free
                }

                // Check overlap using half-open interval: [start, end)
                // Overlap exists if: start1 < end2 AND start2 < end1
                if (reservationStart < existingEnd && existingStart < reservationEnd)
                {
                    throw new InvalidOperationException(
                        $"Table is already reserved at {existingStart:HH:mm} - {existingEnd:HH:mm}. Please choose a different time or table.");
                }
            }
        }

        protected override async Task BeforeUpdate(Database.Reservation entity, ReservationUpsertRequest request)
        {
            // Validate user exists and is active
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == entity.UserId);
            if (user == null)
            {
                throw new InvalidOperationException($"User with ID {entity.UserId} does not exist.");
            }
            if (!user.IsActive)
            {
                throw new InvalidOperationException($"User is not active.");
            }

            // Load restaurant to check working hours
            var restaurant = await _context.Restaurants
                .FirstOrDefaultAsync(r => r.Id == entity.RestaurantId);

            if (restaurant == null)
            {
                throw new InvalidOperationException($"Restaurant with ID {entity.RestaurantId} does not exist.");
            }

            if (!restaurant.IsActive)
            {
                throw new InvalidOperationException($"Restaurant is not active.");
            }

            // Validate table exists and is active
            var table = await _context.Tables
                .FirstOrDefaultAsync(t => t.Id == entity.TableId && t.RestaurantId == entity.RestaurantId);

            if (table == null)
            {
                throw new InvalidOperationException($"Table with ID {entity.TableId} does not exist in restaurant {entity.RestaurantId}.");
            }

            if (!table.IsActive)
            {
                throw new InvalidOperationException($"Table {table.TableNumber} is not active.");
            }

            // Validate number of guests fits table capacity
            if (entity.NumberOfGuests <= 0)
            {
                throw new InvalidOperationException("Number of guests must be greater than zero.");
            }

            if (entity.NumberOfGuests > table.Capacity)
            {
                throw new InvalidOperationException(
                    $"Number of guests ({entity.NumberOfGuests}) exceeds table capacity ({table.Capacity}).");
            }

            // Validate duration is positive
            if (entity.Duration <= TimeSpan.Zero)
            {
                throw new InvalidOperationException("Reservation duration must be greater than zero.");
            }

            // Validate reservation date is not in the past
            var now = DateTime.UtcNow;
            var reservationStart = entity.ReservationDate.Date.Add(entity.ReservationTime);
            
            if (reservationStart < now)
            {
                throw new InvalidOperationException(
                    $"Reservation time {reservationStart:yyyy-MM-dd HH:mm} is in the past. Please select a future date and time.");
            }

            // Calculate end time
            var reservationEnd = reservationStart.Add(entity.Duration);

            // 1. Validate working hours
            // Handle case where close time is next day (e.g., 22:00 to 02:00)
            var restaurantOpenTime = entity.ReservationDate.Date.Add(restaurant.OpenTime);
            var restaurantCloseTime = entity.ReservationDate.Date.Add(restaurant.CloseTime);

            if (restaurant.CloseTime < restaurant.OpenTime)
            {
                // Restaurant closes next day (e.g., opens at 10:00, closes at 02:00 next day)
                restaurantCloseTime = restaurantCloseTime.AddDays(1);
                
                // If reservation spans midnight, check both days
                if (reservationEnd.Date > reservationStart.Date)
                {
                    // Reservation spans midnight - check if it's within working hours
                    // For example: restaurant 22:00-02:00, reservation 23:00-01:00 is OK
                    if (reservationStart < restaurantOpenTime || reservationEnd > restaurantCloseTime)
                    {
                        throw new InvalidOperationException(
                            $"Reservation time {reservationStart:HH:mm} - {reservationEnd:HH:mm} is outside restaurant working hours {restaurant.OpenTime:hh\\:mm} - {restaurant.CloseTime:hh\\:mm}.");
                    }
                }
                else
                {
                    // Reservation doesn't span midnight
                    // Check if reservation is before closing time of previous day or after opening time
                    var previousDayClose = restaurantCloseTime.AddDays(-1);
                    if (reservationStart < restaurantOpenTime && reservationEnd <= previousDayClose)
                    {
                        throw new InvalidOperationException(
                            $"Reservation time {reservationStart:HH:mm} - {reservationEnd:HH:mm} is outside restaurant working hours {restaurant.OpenTime:hh\\:mm} - {restaurant.CloseTime:hh\\:mm}.");
                    }
                }
            }
            else
            {
                // Normal case: restaurant closes same day
                if (reservationStart < restaurantOpenTime || reservationEnd > restaurantCloseTime)
                {
                    throw new InvalidOperationException(
                        $"Reservation time {reservationStart:HH:mm} - {reservationEnd:HH:mm} is outside restaurant working hours {restaurant.OpenTime:hh\\:mm} - {restaurant.CloseTime:hh\\:mm}.");
                }
            }

            // 2. Check if user has overlapping reservations in different restaurants (excluding current reservation)
            // NOTE: User CAN have multiple overlapping reservations in the SAME restaurant (different tables)
            // User CANNOT have overlapping reservations in DIFFERENT restaurants
            // Only check active reservations (not cancelled and not yet completed)
            var reservationEndDate = reservationEnd.Date;
            
            var userOverlappingReservations = await _context.Reservations
                .Where(r => r.UserId == entity.UserId
                    && r.RestaurantId != entity.RestaurantId  // Only check different restaurants
                    && r.Id != entity.Id
                    && r.Status != "Cancelled"
                    && r.CancelledAt == null
                    && (r.ReservationDate.Date == entity.ReservationDate.Date || r.ReservationDate.Date == reservationEndDate))
                .ToListAsync();

            foreach (var existingReservation in userOverlappingReservations)
            {
                var existingStart = existingReservation.ReservationDate.Date.Add(existingReservation.ReservationTime);
                var existingEnd = existingStart.Add(existingReservation.Duration);

                // Only check if existing reservation is still active (not completed)
                // Table release: if reservation has ended, it's no longer blocking
                if (existingEnd <= now)
                {
                    continue; // This reservation has ended, table is free
                }

                // Check overlap using half-open interval: [start, end)
                // Overlap exists if: start1 < end2 AND start2 < end1
                if (reservationStart < existingEnd && existingStart < reservationEnd)
                {
                    throw new InvalidOperationException(
                        $"User already has a reservation at {existingStart:HH:mm} - {existingEnd:HH:mm} in another restaurant. Cannot have overlapping reservations in different restaurants.");
                }
            }

            // 3. Check if table has overlapping reservations (excluding current reservation)
            // Only check active reservations (not cancelled and not yet completed)
            var tableOverlappingReservations = await _context.Reservations
                .Where(r => r.TableId == entity.TableId
                    && r.RestaurantId == entity.RestaurantId
                    && r.Id != entity.Id
                    && r.Status != "Cancelled"
                    && r.CancelledAt == null
                    && (r.ReservationDate.Date == entity.ReservationDate.Date || r.ReservationDate.Date == reservationEndDate))
                .ToListAsync();

            foreach (var existingReservation in tableOverlappingReservations)
            {
                var existingStart = existingReservation.ReservationDate.Date.Add(existingReservation.ReservationTime);
                var existingEnd = existingStart.Add(existingReservation.Duration);

                // Table release: if reservation has ended, it's no longer blocking
                if (existingEnd <= now)
                {
                    continue; // This reservation has ended, table is free
                }

                // Check overlap using half-open interval: [start, end)
                // Overlap exists if: start1 < end2 AND start2 < end1
                if (reservationStart < existingEnd && existingStart < reservationEnd)
                {
                    throw new InvalidOperationException(
                        $"Table is already reserved at {existingStart:HH:mm} - {existingEnd:HH:mm}. Please choose a different time or table.");
                }
            }
        }

        protected override Database.Reservation MapInsertToEntity(Database.Reservation entity, ReservationUpsertRequest request)
        {
            base.MapInsertToEntity(entity, request);
            
            // Set default status if not provided
            if (string.IsNullOrEmpty(entity.Status))
            {
                entity.Status = "Pending";
            }
            
            return entity;
        }

        public override async Task<ReservationResponse> CreateAsync(ReservationUpsertRequest request)
        {
            var entity = new Database.Reservation();
            MapInsertToEntity(entity, request);
            
            // Validate before adding to context
            await BeforeInsert(entity, request);
            
            _context.Set<Database.Reservation>().Add(entity);
            await _context.SaveChangesAsync();
            
            // Reload entity with navigation properties
            entity = await _context.Reservations
                .Include(r => r.User)
                .Include(r => r.Restaurant)
                .Include(r => r.Table)
                .FirstOrDefaultAsync(r => r.Id == entity.Id);
            
            if (entity == null)
            {
                throw new InvalidOperationException("Failed to reload reservation after creation.");
            }
            
            return MapToResponse(entity);
        }

        protected override IQueryable<Database.Reservation> ApplyFilter(IQueryable<Database.Reservation> query, ReservationSearchObject search)
        {
            query = query.Include(r => r.User)
                        .Include(r => r.Restaurant)
                        .Include(r => r.Table);

            if (search.UserId.HasValue)
            {
                query = query.Where(r => r.UserId == search.UserId.Value);
            }

            if (search.RestaurantId.HasValue)
            {
                query = query.Where(r => r.RestaurantId == search.RestaurantId.Value);
            }

            if (search.TableId.HasValue)
            {
                query = query.Where(r => r.TableId == search.TableId.Value);
            }

            if (!string.IsNullOrEmpty(search.Status))
            {
                query = query.Where(r => r.Status == search.Status);
            }

            if (search.ReservationDateFrom.HasValue)
            {
                query = query.Where(r => r.ReservationDate >= search.ReservationDateFrom.Value);
            }

            if (search.ReservationDateTo.HasValue)
            {
                query = query.Where(r => r.ReservationDate <= search.ReservationDateTo.Value);
            }

            return query;
        }

        protected override ReservationResponse MapToResponse(Database.Reservation entity)
        {
            if (entity == null)
                return null!;
                
            return new ReservationResponse
            {
                Id = entity.Id,
                UserId = entity.UserId,
                UserName = entity.User != null ? $"{entity.User.FirstName} {entity.User.LastName}" : string.Empty,
                RestaurantId = entity.RestaurantId,
                RestaurantName = entity.Restaurant != null ? entity.Restaurant.Name : string.Empty,
                TableId = entity.TableId,
                TableNumber = entity.Table != null ? entity.Table.TableNumber : string.Empty,
                ReservationDate = entity.ReservationDate,
                ReservationTime = entity.ReservationTime,
                Duration = entity.Duration,
                NumberOfGuests = entity.NumberOfGuests,
                Status = entity.Status,
                SpecialRequests = entity.SpecialRequests,
                QRCode = entity.QRCode,
                CreatedAt = entity.CreatedAt,
                ConfirmedAt = entity.ConfirmedAt,
                CancelledAt = entity.CancelledAt,
                CancellationReason = entity.CancellationReason
            };
        }
        
        public override async Task<ReservationResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Reservations
                .Include(r => r.User)
                .Include(r => r.Restaurant)
                .Include(r => r.Table)
                .FirstOrDefaultAsync(r => r.Id == id);
                
            if (entity == null)
                return null;
                
            return MapToResponse(entity);
        }

        public async Task<object> GetTodayReservationsAsync(int? restaurantId = null)
        {
            var today = DateTime.UtcNow.Date;
            var tomorrow = today.AddDays(1);

            var query = _context.Reservations
                .Where(r => r.ReservationDate >= today && r.ReservationDate < tomorrow);

            if (restaurantId.HasValue)
            {
                query = query.Where(r => r.RestaurantId == restaurantId.Value);
            }

            var reservations = await query.ToListAsync();

            var pending = reservations.Count(r => r.Status == "Pending");
            var confirmed = reservations.Count(r => r.Status == "Confirmed");
            var completed = reservations.Count(r => r.Status == "Completed");

            return new
            {
                pending = pending,
                confirmed = confirmed,
                completed = completed
            };
        }
    }
}


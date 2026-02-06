using eCommerce.Model;
using eCommerce.Model.Messages;
using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using eCommerce.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    public class ReservationService : BaseCRUDService<ReservationResponse, ReservationSearchObject, Database.Reservation, ReservationUpsertRequest, ReservationUpsertRequest>, IReservationService
    {
        private readonly ILoyaltyService _loyaltyService;
        private readonly IReservationNotificationPublisher _notificationPublisher;
        private readonly ILogger<ReservationService> _logger;

        public ReservationService(
            eCommerceDbContext context,
            IMapper mapper,
            ILoyaltyService loyaltyService,
            IReservationNotificationPublisher notificationPublisher,
            ILogger<ReservationService> logger) : base(context, mapper)
        {
            _loyaltyService = loyaltyService;
            _notificationPublisher = notificationPublisher;
            _logger = logger;
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
                    && r.State != ReservationState.Cancelled
                    && r.State != ReservationState.Expired
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
                    && r.State != ReservationState.Cancelled
                    && r.State != ReservationState.Expired
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
                    && r.State != ReservationState.Cancelled
                    && r.State != ReservationState.Expired
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
                    && r.State != ReservationState.Cancelled
                    && r.State != ReservationState.Expired
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
            
            // State defaults to Requested via the property initializer, no need to set it here
            // The entity will be created with State = ReservationState.Requested by default
            
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

            if (search.State.HasValue)
            {
                query = query.Where(r => r.State == search.State.Value);
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
                TableId = entity.TableId ?? 0,
                TableNumber = entity.Table != null ? entity.Table.TableNumber : string.Empty,
                ReservationDate = entity.ReservationDate,
                ReservationTime = entity.ReservationTime,
                Duration = entity.Duration,
                NumberOfGuests = entity.NumberOfGuests,
                Status = entity.State.ToString(),
                SpecialRequests = entity.SpecialRequests,
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

            var pending = reservations.Count(r => r.State == ReservationState.Requested);
            var confirmed = reservations.Count(r => r.State == ReservationState.Confirmed);
            var completed = reservations.Count(r => r.State == ReservationState.Completed);

            return new
            {
                pending = pending,
                confirmed = confirmed,
                completed = completed
            };
        }

        public async Task<object> GetAllReservationsAsync(int? restaurantId = null)
        {
            var query = _context.Reservations.AsQueryable();

            if (restaurantId.HasValue)
            {
                query = query.Where(r => r.RestaurantId == restaurantId.Value);
            }

            var reservations = await query.ToListAsync();

            var pending = reservations.Count(r => r.State == ReservationState.Requested);
            var confirmed = reservations.Count(r => r.State == ReservationState.Confirmed);
            var completed = reservations.Count(r => r.State == ReservationState.Completed);
            var cancelled = reservations.Count(r => r.State == ReservationState.Cancelled);
            var expired = reservations.Count(r => r.State == ReservationState.Expired);

            return new
            {
                pending = pending,
                confirmed = confirmed,
                completed = completed,
                cancelled = cancelled,
                expired = expired
            };
        }

        public async Task<List<ReservationResponse>> GetTodayReservationsByStateAsync(ReservationState state, int? restaurantId = null)
        {
            var today = DateTime.UtcNow.Date;
            var tomorrow = today.AddDays(1);

            var query = _context.Reservations
                .Include(r => r.User)
                .Include(r => r.Restaurant)
                .Include(r => r.Table)
                .Where(r => r.ReservationDate >= today && 
                           r.ReservationDate < tomorrow &&
                           r.State == state);

            if (restaurantId.HasValue)
            {
                query = query.Where(r => r.RestaurantId == restaurantId.Value);
            }

            var list = await query.ToListAsync();
            return list.Select(MapToResponse).ToList();
        }

        public async Task<List<ReservationResponse>> GetAllReservationsByStateAsync(ReservationState state, int? restaurantId = null)
        {
            var query = _context.Reservations
                .Include(r => r.User)
                .Include(r => r.Restaurant)
                .Include(r => r.Table)
                .Where(r => r.State == state);

            if (restaurantId.HasValue)
            {
                query = query.Where(r => r.RestaurantId == restaurantId.Value);
            }

            var list = await query.ToListAsync();
            return list.Select(MapToResponse).ToList();
        }

        public async Task<ReservationResponse> ConfirmReservationAsync(int id)
        {
            var entity = await _context.Reservations
                .Include(r => r.User)
                .Include(r => r.Restaurant)
                .Include(r => r.Table)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (entity == null)
            {
                throw new InvalidOperationException($"Reservation with ID {id} not found.");
            }

            entity.Confirm();
            await _context.SaveChangesAsync();

            await SaveNotificationToDatabaseAsync(entity, "Confirmed", null);
            _ = PublishStatusChangedAsync(entity, ReservationState.Requested.ToString(), ReservationState.Confirmed.ToString(), cancellationReason: null);

            // Reload with navigation properties
            entity = await _context.Reservations
                .Include(r => r.User)
                .Include(r => r.Restaurant)
                .Include(r => r.Table)
                .FirstOrDefaultAsync(r => r.Id == id);

            return MapToResponse(entity);
        }

        public async Task<ReservationResponse> CancelReservationAsync(int id, string? reason = null)
        {
            var entity = await _context.Reservations
                .Include(r => r.User)
                .Include(r => r.Restaurant)
                .Include(r => r.Table)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (entity == null)
            {
                throw new InvalidOperationException($"Reservation with ID {id} not found.");
            }

            var previousState = entity.State;
            entity.Cancel(reason);
            await _context.SaveChangesAsync();

            await SaveNotificationToDatabaseAsync(entity, "Cancelled", entity.CancellationReason);
            _ = PublishStatusChangedAsync(entity, previousState.ToString(), ReservationState.Cancelled.ToString(), entity.CancellationReason);

            // Reload with navigation properties
            entity = await _context.Reservations
                .Include(r => r.User)
                .Include(r => r.Restaurant)
                .Include(r => r.Table)
                .FirstOrDefaultAsync(r => r.Id == id);

            return MapToResponse(entity);
        }

        public async Task<ReservationResponse> CompleteReservationAsync(int id)
        {
            var entity = await _context.Reservations
                .Include(r => r.User)
                .Include(r => r.Restaurant)
                .Include(r => r.Table)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (entity == null)
            {
                throw new InvalidOperationException($"Reservation with ID {id} not found.");
            }

            entity.Complete();
            await _loyaltyService.AddPointsForCompletedReservationAsync(entity);
            await _context.SaveChangesAsync();

            await SaveNotificationToDatabaseAsync(entity, "Completed", null);
            _ = PublishStatusChangedAsync(entity, ReservationState.Confirmed.ToString(), ReservationState.Completed.ToString(), cancellationReason: null);

            // Reload with navigation properties
            entity = await _context.Reservations
                .Include(r => r.User)
                .Include(r => r.Restaurant)
                .Include(r => r.Table)
                .FirstOrDefaultAsync(r => r.Id == id);

            return MapToResponse(entity);
        }

        private async Task SaveNotificationToDatabaseAsync(Database.Reservation entity, string newState, string? cancellationReason)
        {
            var (title, message) = BuildNotificationText(
                entity.Restaurant?.Name ?? "",
                entity.ReservationDate,
                entity.ReservationTime,
                newState,
                cancellationReason);
            _context.Notifications.Add(new Database.Notification
            {
                UserId = entity.UserId,
                Type = "ReservationStatusChanged",
                Title = title,
                Message = message,
                RelatedReservationId = entity.Id,
                IsRead = false,
                SentAt = DateTime.UtcNow
            });
            await _context.SaveChangesAsync();
        }

        private static (string Title, string Message) BuildNotificationText(string restaurantName, DateTime reservationDate, TimeSpan reservationTime, string newState, string? cancellationReason)
        {
            var dateStr = reservationDate.ToString("yyyy-MM-dd");
            var timeStr = $"{reservationTime.Hours:D2}:{reservationTime.Minutes:D2}";
            var place = string.IsNullOrWhiteSpace(restaurantName) ? "your reservation" : restaurantName;
            return newState switch
            {
                "Confirmed" => (
                    "Reservation confirmed",
                    $"Your reservation at {place} on {dateStr} at {timeStr} has been confirmed."),
                "Cancelled" => (
                    "Reservation cancelled",
                    string.IsNullOrWhiteSpace(cancellationReason)
                        ? $"Your reservation at {place} on {dateStr} at {timeStr} has been cancelled."
                        : $"Your reservation at {place} on {dateStr} at {timeStr} has been cancelled. Reason: {cancellationReason}"),
                "Completed" => (
                    "Reservation completed",
                    $"Your reservation at {place} on {dateStr} at {timeStr} has been marked as completed. Thank you!"),
                _ => (
                    "Reservation update",
                    $"Your reservation at {place} on {dateStr} at {timeStr} is now {newState}.")
            };
        }

        private Task PublishStatusChangedAsync(Database.Reservation entity, string previousState, string newState, string? cancellationReason)
        {
            var message = new ReservationStatusChangedMessage
            {
                ReservationId = entity.Id,
                UserId = entity.UserId,
                PreviousState = previousState,
                NewState = newState,
                RestaurantName = entity.Restaurant?.Name ?? "",
                ReservationDate = entity.ReservationDate,
                ReservationTime = entity.ReservationTime,
                CancellationReason = cancellationReason
            };
            return PublishMessageInBackgroundAsync(message);
        }

        private async Task PublishMessageInBackgroundAsync(ReservationStatusChangedMessage message)
        {
            try
            {
                await _notificationPublisher.PublishReservationStatusChangedAsync(message);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to publish reservation status change for reservation {ReservationId}. User notification may not be sent.", message.ReservationId);
            }
        }
    }
}


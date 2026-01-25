using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using eCommerce.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;
using eCommerce.Model;

namespace eCommerce.Services
{
    public class TableService : BaseCRUDService<TableResponse, TableSearchObject, Database.Table, TableUpsertRequest, TableUpsertRequest>, ITableService
    {
        public TableService(eCommerceDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<TableResponse> CreateAsync(TableUpsertRequest request)
        {
            var entity = new Database.Table();
            MapInsertToEntity(entity, request);
            _context.Set<Database.Table>().Add(entity);

            await BeforeInsert(entity, request);

            await _context.SaveChangesAsync();
            
            // Reload entity with navigation properties
            entity = await _context.Tables
                .Include(t => t.Restaurant)
                .FirstOrDefaultAsync(t => t.Id == entity.Id);
            
            return MapToResponse(entity);
        }

        protected override IQueryable<Database.Table> ApplyFilter(IQueryable<Database.Table> query, TableSearchObject search)
        {
            query = query.Include(t => t.Restaurant);

            if (search.RestaurantId.HasValue)
            {
                query = query.Where(t => t.RestaurantId == search.RestaurantId.Value);
            }

            if (!string.IsNullOrEmpty(search.TableNumber))
            {
                query = query.Where(t => t.TableNumber.Contains(search.TableNumber));
            }

            if (search.Capacity.HasValue)
            {
                query = query.Where(t => t.Capacity == search.Capacity.Value);
            }

            if (search.TableType.HasValue)
            {
                query = query.Where(t => t.TableType == search.TableType.Value);
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(t => t.IsActive == search.IsActive.Value);
            }
            
            // CRITICAL FIX: Add OrderBy to ensure consistent ordering (newest first)
            // This ensures newly created tables (higher IDs) appear first
            query = query.OrderByDescending(t => t.Id);

            return query;
        }

        protected override TableResponse MapToResponse(Database.Table entity)
        {
            if (entity == null)
                return null!;
                
            // Safely handle TableType enum - it might be null or invalid for old records
            TableType? tableType = null;
            if (entity.TableType.HasValue && Enum.IsDefined(typeof(TableType), entity.TableType.Value))
            {
                tableType = entity.TableType.Value;
            }
                
            return new TableResponse
            {
                Id = entity.Id,
                RestaurantId = entity.RestaurantId,
                RestaurantName = entity.Restaurant != null ? entity.Restaurant.Name : string.Empty,
                TableNumber = entity.TableNumber,
                Capacity = entity.Capacity,
                PositionX = entity.PositionX,
                PositionY = entity.PositionY,
                TableType = tableType,
                IsActive = entity.IsActive
            };
        }
        
        public override async Task<TableResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Tables
                .Include(t => t.Restaurant)
                .FirstOrDefaultAsync(t => t.Id == id);
                
            if (entity == null)
                return null;
                
            return MapToResponse(entity);
        }

        public async Task<object> GetOccupancyAsync(int? restaurantId = null)
        {
            var query = _context.Tables.Where(t => t.IsActive);
            
            if (restaurantId.HasValue)
            {
                query = query.Where(t => t.RestaurantId == restaurantId.Value);
            }
            
            var total = await query.CountAsync();
            
            // Count occupied tables (tables with currently active reservations)
            // Use local time since reservations are stored with local date/time
            var now = DateTime.Now; // Use local time instead of UTC
            var today = now.Date;
            var tomorrow = today.AddDays(1);
            
            // Get all reservations for today that are not cancelled
            var allReservations = await _context.Reservations
                .Where(r => r.ReservationDate >= today && 
                           r.ReservationDate < tomorrow &&
                           (r.State == eCommerce.Model.ReservationState.Confirmed || r.State == eCommerce.Model.ReservationState.Requested) &&
                           r.CancelledAt == null)
                .ToListAsync();
            
            if (restaurantId.HasValue)
            {
                allReservations = allReservations.Where(r => r.RestaurantId == restaurantId.Value).ToList();
            }
            
            // Filter to only currently active reservations (now is within reservation time window)
            // ReservationDate is stored as date only, ReservationTime is TimeSpan
            // We combine them to get full DateTime and compare with current local time
            var currentlyActiveReservations = allReservations.Where(r =>
            {
                // Combine reservation date and time to get full DateTime (in local time)
                var reservationStart = r.ReservationDate.Date.Add(r.ReservationTime);
                var reservationEnd = reservationStart.Add(r.Duration);
                
                // Compare with current local time
                return now >= reservationStart && now < reservationEnd;
            }).ToList();
            
            // Get distinct table IDs that are currently occupied
            var occupiedTableIds = currentlyActiveReservations
                .Select(r => r.TableId)
                .Distinct()
                .ToList();
            
            // Filter occupied tables by restaurant if needed
            if (restaurantId.HasValue)
            {
                var restaurantTableIds = await query.Select(t => t.Id).ToListAsync();
                occupiedTableIds = occupiedTableIds.Where(id => restaurantTableIds.Contains(id)).ToList();
            }
            
            var occupied = occupiedTableIds.Count;
            var percentage = total > 0 ? (double)occupied / total * 100 : 0.0;

            return new
            {
                occupied = occupied,
                total = total,
                percentage = Math.Round(percentage, 2)
            };
        }
    }
}


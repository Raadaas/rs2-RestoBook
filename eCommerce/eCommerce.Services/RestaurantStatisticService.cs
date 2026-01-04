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
    public class RestaurantStatisticService : BaseCRUDService<RestaurantStatisticResponse, RestaurantStatisticSearchObject, Database.RestaurantStatistic, RestaurantStatisticUpsertRequest, RestaurantStatisticUpsertRequest>, IRestaurantStatisticService
    {
        public RestaurantStatisticService(eCommerceDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<RestaurantStatisticResponse> CreateAsync(RestaurantStatisticUpsertRequest request)
        {
            var entity = new Database.RestaurantStatistic();
            MapInsertToEntity(entity, request);
            _context.Set<Database.RestaurantStatistic>().Add(entity);

            await BeforeInsert(entity, request);

            await _context.SaveChangesAsync();
            
            // Reload entity with navigation properties
            entity = await _context.RestaurantStatistics
                .Include(rs => rs.Restaurant)
                .FirstOrDefaultAsync(rs => rs.Id == entity.Id);
            
            return MapToResponse(entity);
        }

        protected override IQueryable<Database.RestaurantStatistic> ApplyFilter(IQueryable<Database.RestaurantStatistic> query, RestaurantStatisticSearchObject search)
        {
            query = query.Include(rs => rs.Restaurant);

            if (search.RestaurantId.HasValue)
            {
                query = query.Where(rs => rs.RestaurantId == search.RestaurantId.Value);
            }

            if (search.DateFrom.HasValue)
            {
                query = query.Where(rs => rs.Date >= search.DateFrom.Value);
            }

            if (search.DateTo.HasValue)
            {
                query = query.Where(rs => rs.Date <= search.DateTo.Value);
            }

            return query;
        }

        protected override RestaurantStatisticResponse MapToResponse(Database.RestaurantStatistic entity)
        {
            if (entity == null)
                return null!;
                
            return new RestaurantStatisticResponse
            {
                Id = entity.Id,
                RestaurantId = entity.RestaurantId,
                RestaurantName = entity.Restaurant != null ? entity.Restaurant.Name : string.Empty,
                Date = entity.Date,
                TotalReservations = entity.TotalReservations,
                CompletedReservations = entity.CompletedReservations,
                CancelledReservations = entity.CancelledReservations,
                NoShows = entity.NoShows,
                AverageOccupancy = entity.AverageOccupancy,
                PeakHour = entity.PeakHour,
                Revenue = entity.Revenue
            };
        }
        
        public override async Task<RestaurantStatisticResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.RestaurantStatistics
                .Include(rs => rs.Restaurant)
                .FirstOrDefaultAsync(rs => rs.Id == id);
                
            if (entity == null)
                return null;
                
            return MapToResponse(entity);
        }
    }
}


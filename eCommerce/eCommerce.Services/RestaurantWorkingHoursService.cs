using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using eCommerce.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    public class RestaurantWorkingHoursService : BaseCRUDService<RestaurantWorkingHoursResponse, RestaurantWorkingHoursSearchObject, Database.RestaurantWorkingHours, RestaurantWorkingHoursUpsertRequest, RestaurantWorkingHoursUpsertRequest>, IRestaurantWorkingHoursService
    {
        public RestaurantWorkingHoursService(eCommerceDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<RestaurantWorkingHoursResponse> CreateAsync(RestaurantWorkingHoursUpsertRequest request)
        {
            var entity = new Database.RestaurantWorkingHours();
            MapInsertToEntity(entity, request);
            _context.Set<Database.RestaurantWorkingHours>().Add(entity);

            await BeforeInsert(entity, request);

            await _context.SaveChangesAsync();
            
            // Reload entity with navigation properties
            entity = await _context.RestaurantWorkingHours
                .Include(rwh => rwh.Restaurant)
                .FirstOrDefaultAsync(rwh => rwh.Id == entity.Id);
            
            return MapToResponse(entity);
        }

        protected override IQueryable<Database.RestaurantWorkingHours> ApplyFilter(IQueryable<Database.RestaurantWorkingHours> query, RestaurantWorkingHoursSearchObject search)
        {
            query = query.Include(rwh => rwh.Restaurant);

            if (search.RestaurantId.HasValue)
            {
                query = query.Where(rwh => rwh.RestaurantId == search.RestaurantId.Value);
            }

            if (search.DayOfWeek.HasValue)
            {
                query = query.Where(rwh => rwh.DayOfWeek == search.DayOfWeek.Value);
            }

            if (search.IsClosed.HasValue)
            {
                query = query.Where(rwh => rwh.IsClosed == search.IsClosed.Value);
            }

            return query;
        }

        protected override RestaurantWorkingHoursResponse MapToResponse(Database.RestaurantWorkingHours entity)
        {
            if (entity == null)
                return null!;
                
            return new RestaurantWorkingHoursResponse
            {
                Id = entity.Id,
                RestaurantId = entity.RestaurantId,
                RestaurantName = entity.Restaurant != null ? entity.Restaurant.Name : string.Empty,
                DayOfWeek = entity.DayOfWeek,
                OpenTime = entity.OpenTime,
                CloseTime = entity.CloseTime,
                IsClosed = entity.IsClosed
            };
        }
        
        public override async Task<RestaurantWorkingHoursResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.RestaurantWorkingHours
                .Include(rwh => rwh.Restaurant)
                .FirstOrDefaultAsync(rwh => rwh.Id == id);
                
            if (entity == null)
                return null;
                
            return MapToResponse(entity);
        }
    }
}


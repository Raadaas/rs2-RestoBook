using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using eCommerce.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System.Linq;

namespace eCommerce.Services
{
    public class RestaurantService : BaseCRUDService<RestaurantResponse, RestaurantSearchObject, Database.Restaurant, RestaurantUpsertRequest, RestaurantUpsertRequest>, IRestaurantService
    {
        public RestaurantService(eCommerceDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<RestaurantResponse> CreateAsync(RestaurantUpsertRequest request)
        {
            var entity = new Database.Restaurant();
            MapInsertToEntity(entity, request);
            _context.Set<Database.Restaurant>().Add(entity);

            await BeforeInsert(entity, request);

            await _context.SaveChangesAsync();
            
            // Reload entity with navigation properties
            entity = await _context.Restaurants
                .Include(r => r.Owner)
                .Include(r => r.City)
                .Include(r => r.CuisineType)
                .FirstOrDefaultAsync(r => r.Id == entity.Id);
            
            return MapToResponse(entity);
        }

        protected override IQueryable<Database.Restaurant> ApplyFilter(IQueryable<Database.Restaurant> query, RestaurantSearchObject search)
        {
            query = query.Include(r => r.Owner)
                        .Include(r => r.City)
                        .Include(r => r.CuisineType);

            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(r => r.Name.Contains(search.Name));
            }

            if (search.CityId.HasValue)
            {
                query = query.Where(r => r.CityId == search.CityId.Value);
            }

            if (search.CuisineTypeId.HasValue)
            {
                query = query.Where(r => r.CuisineTypeId == search.CuisineTypeId.Value);
            }

            if (search.OwnerId.HasValue)
            {
                query = query.Where(r => r.OwnerId == search.OwnerId.Value);
            }

            if (search.PriceRange.HasValue)
            {
                query = query.Where(r => r.PriceRange == search.PriceRange.Value);
            }

            if (search.HasParking.HasValue)
            {
                query = query.Where(r => r.HasParking == search.HasParking.Value);
            }

            if (search.HasTerrace.HasValue)
            {
                query = query.Where(r => r.HasTerrace == search.HasTerrace.Value);
            }

            if (search.IsKidFriendly.HasValue)
            {
                query = query.Where(r => r.IsKidFriendly == search.IsKidFriendly.Value);
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(r => r.IsActive == search.IsActive.Value);
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(r => r.Name.Contains(search.FTS) || 
                    (r.Description != null && r.Description.Contains(search.FTS)) ||
                    r.Address.Contains(search.FTS));
            }

            return query;
        }

        protected override RestaurantResponse MapToResponse(Database.Restaurant entity)
        {
            if (entity == null)
                return null!;
                
            return new RestaurantResponse
            {
                Id = entity.Id,
                OwnerId = entity.OwnerId,
                OwnerName = entity.Owner != null ? $"{entity.Owner.FirstName} {entity.Owner.LastName}" : string.Empty,
                Name = entity.Name,
                Description = entity.Description,
                Address = entity.Address,
                CityId = entity.CityId,
                CityName = entity.City != null ? entity.City.Name : string.Empty,
                Latitude = entity.Latitude,
                Longitude = entity.Longitude,
                PhoneNumber = entity.PhoneNumber,
                Email = entity.Email,
                CuisineTypeId = entity.CuisineTypeId,
                CuisineTypeName = entity.CuisineType != null ? entity.CuisineType.Name : string.Empty,
                PriceRange = entity.PriceRange,
                AverageRating = entity.AverageRating,
                TotalReviews = entity.TotalReviews,
                HasParking = entity.HasParking,
                HasTerrace = entity.HasTerrace,
                IsKidFriendly = entity.IsKidFriendly,
                OpenTime = entity.OpenTime,
                CloseTime = entity.CloseTime,
                CreatedAt = entity.CreatedAt,
                IsActive = entity.IsActive
            };
        }
        
        public override async Task<RestaurantResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Restaurants
                .Include(r => r.Owner)
                .Include(r => r.City)
                .Include(r => r.CuisineType)
                .FirstOrDefaultAsync(r => r.Id == id);
                
            if (entity == null)
                return null;
                
            return MapToResponse(entity);
        }
    }
}

using eCommerce.Model;
using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using eCommerce.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    public class RestaurantService : BaseCRUDService<RestaurantResponse, RestaurantSearchObject, Database.Restaurant, RestaurantUpsertRequest, RestaurantUpsertRequest>, IRestaurantService
    {
        private readonly ContentBasedRestaurantRecommender _recommender;

        public RestaurantService(eCommerceDbContext context, IMapper mapper, ContentBasedRestaurantRecommender recommender) : base(context, mapper)
        {
            _recommender = recommender;
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

        public async Task<List<RestaurantResponse>> GetRecommendedForUserAsync(int userId, int count = 10)
        {
            var likedRestaurantIds = await GetLikedRestaurantIdsAsync(userId);
            // Uključujemo SVE aktivne restorane kao kandidate – i one gdje je korisnik već bio.
            // Rangiranje po sličnosti s profilom: mjesta gdje ima najviše rezervacija bit će najsličnija i na vrhu.
            var candidates = await _context.Restaurants
                .Where(r => r.IsActive)
                .Select(r => r.Id)
                .ToListAsync();

            if (candidates.Count == 0)
                return new List<RestaurantResponse>();

            List<int> topIds;
            if (_recommender.IsBuilt)
            {
                var userProfile = _recommender.GetUserProfileVector(likedRestaurantIds);
                if (userProfile != null)
                {
                    topIds = _recommender.GetTopN(userProfile, candidates, count).ToList();
                }
                else
                {
                    // Nema profila (nema completed rezervacija ni recenzija ≥4): top po ocjeni
                    topIds = await _context.Restaurants
                        .Where(r => r.IsActive)
                        .OrderByDescending(r => r.AverageRating ?? 0)
                        .Take(count)
                        .Select(r => r.Id)
                        .ToListAsync();
                }
                if (topIds.Count == 0 && candidates.Count > 0)
                    topIds = await _context.Restaurants
                        .Where(r => r.IsActive)
                        .OrderByDescending(r => r.AverageRating ?? 0)
                        .Take(count)
                        .Select(r => r.Id)
                        .ToListAsync();
            }
            else
            {
                topIds = await _context.Restaurants
                    .Where(r => r.IsActive)
                    .OrderByDescending(r => r.AverageRating ?? 0)
                    .Take(count)
                    .Select(r => r.Id)
                    .ToListAsync();
            }

            var ordered = await _context.Restaurants
                .Include(r => r.Owner)
                .Include(r => r.City)
                .Include(r => r.CuisineType)
                .Where(r => topIds.Contains(r.Id))
                .ToListAsync();
            var byId = ordered.ToDictionary(r => r.Id);
            return topIds.Where(id => byId.ContainsKey(id)).Select(id => MapToResponse(byId[id])).ToList();
        }

        private async Task<List<int>> GetLikedRestaurantIdsAsync(int userId)
        {
            var fromReservations = await _context.Reservations
                .Where(r => r.UserId == userId && r.State == ReservationState.Completed)
                .Select(r => r.RestaurantId)
                .Distinct()
                .ToListAsync();
            var fromReviews = await _context.Reviews
                .Where(r => r.UserId == userId && r.Rating >= 4)
                .Select(r => r.RestaurantId)
                .Distinct()
                .ToListAsync();
            return fromReservations.Union(fromReviews).Distinct().ToList();
        }
    }
}

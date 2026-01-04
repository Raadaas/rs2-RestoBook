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
    public class ReviewService : BaseCRUDService<ReviewResponse, ReviewSearchObject, Database.Review, ReviewUpsertRequest, ReviewUpsertRequest>, IReviewService
    {
        public ReviewService(eCommerceDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<ReviewResponse> CreateAsync(ReviewUpsertRequest request)
        {
            var entity = new Database.Review();
            MapInsertToEntity(entity, request);
            _context.Set<Database.Review>().Add(entity);

            await BeforeInsert(entity, request);

            await _context.SaveChangesAsync();
            
            // Reload entity with navigation properties
            entity = await _context.Reviews
                .Include(r => r.Reservation)
                .Include(r => r.User)
                .Include(r => r.Restaurant)
                .FirstOrDefaultAsync(r => r.Id == entity.Id);
            
            return MapToResponse(entity);
        }

        protected override IQueryable<Database.Review> ApplyFilter(IQueryable<Database.Review> query, ReviewSearchObject search)
        {
            query = query.Include(r => r.Reservation)
                        .Include(r => r.User)
                        .Include(r => r.Restaurant);

            if (search.ReservationId.HasValue)
            {
                query = query.Where(r => r.ReservationId == search.ReservationId.Value);
            }

            if (search.UserId.HasValue)
            {
                query = query.Where(r => r.UserId == search.UserId.Value);
            }

            if (search.RestaurantId.HasValue)
            {
                query = query.Where(r => r.RestaurantId == search.RestaurantId.Value);
            }

            if (search.Rating.HasValue)
            {
                query = query.Where(r => r.Rating == search.Rating.Value);
            }

            if (search.IsVerified.HasValue)
            {
                query = query.Where(r => r.IsVerified == search.IsVerified.Value);
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(r => r.Comment != null && r.Comment.Contains(search.FTS));
            }

            return query;
        }

        protected override ReviewResponse MapToResponse(Database.Review entity)
        {
            if (entity == null)
                return null!;
                
            return new ReviewResponse
            {
                Id = entity.Id,
                ReservationId = entity.ReservationId,
                UserId = entity.UserId,
                UserName = entity.User != null ? $"{entity.User.FirstName} {entity.User.LastName}" : string.Empty,
                RestaurantId = entity.RestaurantId,
                RestaurantName = entity.Restaurant != null ? entity.Restaurant.Name : string.Empty,
                Rating = entity.Rating,
                Comment = entity.Comment,
                FoodQuality = entity.FoodQuality,
                ServiceQuality = entity.ServiceQuality,
                AmbienceRating = entity.AmbienceRating,
                ValueForMoney = entity.ValueForMoney,
                CreatedAt = entity.CreatedAt,
                IsVerified = entity.IsVerified
            };
        }
        
        public override async Task<ReviewResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Reviews
                .Include(r => r.Reservation)
                .Include(r => r.User)
                .Include(r => r.Restaurant)
                .FirstOrDefaultAsync(r => r.Id == id);
                
            if (entity == null)
                return null;
                
            return MapToResponse(entity);
        }
    }
}


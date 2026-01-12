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
    public class SpecialOfferService : BaseCRUDService<SpecialOfferResponse, SpecialOfferSearchObject, Database.SpecialOffer, SpecialOfferUpsertRequest, SpecialOfferUpsertRequest>, ISpecialOfferService
    {
        public SpecialOfferService(eCommerceDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<SpecialOfferResponse> CreateAsync(SpecialOfferUpsertRequest request)
        {
            var entity = new Database.SpecialOffer();
            MapInsertToEntity(entity, request);
            _context.Set<Database.SpecialOffer>().Add(entity);

            await BeforeInsert(entity, request);

            await _context.SaveChangesAsync();
            
            // Reload entity with navigation properties
            entity = await _context.SpecialOffers
                .Include(s => s.Restaurant)
                .FirstOrDefaultAsync(s => s.Id == entity.Id);
            
            return MapToResponse(entity);
        }

        public override async Task<PagedResult<SpecialOfferResponse>> GetAsync(SpecialOfferSearchObject search)
        {
            // Automatically deactivate expired special offers before fetching
            var now = DateTime.UtcNow;
            var expiredOffers = await _context.SpecialOffers
                .Where(s => s.ValidTo < now && s.IsActive)
                .ToListAsync();
            
            if (expiredOffers.Any())
            {
                foreach (var offer in expiredOffers)
                {
                    offer.IsActive = false;
                }
                await _context.SaveChangesAsync();
            }

            // Call base GetAsync which will apply filters and return results
            return await base.GetAsync(search);
        }

        protected override IQueryable<Database.SpecialOffer> ApplyFilter(IQueryable<Database.SpecialOffer> query, SpecialOfferSearchObject search)
        {
            query = query.Include(s => s.Restaurant);

            if (search.RestaurantId.HasValue)
            {
                query = query.Where(s => s.RestaurantId == search.RestaurantId.Value);
            }

            if (!string.IsNullOrEmpty(search.Title))
            {
                query = query.Where(s => s.Title.Contains(search.Title));
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(s => s.IsActive == search.IsActive.Value);
            }

            if (search.ValidFrom.HasValue)
            {
                query = query.Where(s => s.ValidFrom >= search.ValidFrom.Value);
            }

            if (search.ValidTo.HasValue)
            {
                query = query.Where(s => s.ValidTo <= search.ValidTo.Value);
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(s => s.Title.Contains(search.FTS) || 
                    (s.Description != null && s.Description.Contains(search.FTS)));
            }

            return query;
        }

        protected override SpecialOfferResponse MapToResponse(Database.SpecialOffer entity)
        {
            if (entity == null)
                return null!;
                
            return new SpecialOfferResponse
            {
                Id = entity.Id,
                RestaurantId = entity.RestaurantId,
                RestaurantName = entity.Restaurant != null ? entity.Restaurant.Name : string.Empty,
                Title = entity.Title,
                Description = entity.Description,
                Price = entity.Price,
                ValidFrom = entity.ValidFrom,
                ValidTo = entity.ValidTo,
                IsActive = entity.IsActive,
                CreatedAt = entity.CreatedAt
            };
        }
        
        public override async Task<SpecialOfferResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.SpecialOffers
                .Include(s => s.Restaurant)
                .FirstOrDefaultAsync(s => s.Id == id);
                
            if (entity == null)
                return null;
                
            return MapToResponse(entity);
        }
    }
}


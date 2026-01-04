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
    public class MenuItemService : BaseCRUDService<MenuItemResponse, MenuItemSearchObject, Database.MenuItem, MenuItemUpsertRequest, MenuItemUpsertRequest>, IMenuItemService
    {
        public MenuItemService(eCommerceDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<MenuItemResponse> CreateAsync(MenuItemUpsertRequest request)
        {
            var entity = new Database.MenuItem();
            MapInsertToEntity(entity, request);
            _context.Set<Database.MenuItem>().Add(entity);

            await BeforeInsert(entity, request);

            await _context.SaveChangesAsync();
            
            // Reload entity with navigation properties
            entity = await _context.MenuItems
                .Include(m => m.Restaurant)
                .FirstOrDefaultAsync(m => m.Id == entity.Id);
            
            return MapToResponse(entity);
        }

        protected override IQueryable<Database.MenuItem> ApplyFilter(IQueryable<Database.MenuItem> query, MenuItemSearchObject search)
        {
            query = query.Include(m => m.Restaurant);

            if (search.RestaurantId.HasValue)
            {
                query = query.Where(m => m.RestaurantId == search.RestaurantId.Value);
            }

            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(m => m.Name.Contains(search.Name));
            }

            if (!string.IsNullOrEmpty(search.Category))
            {
                query = query.Where(m => m.Category != null && m.Category.Contains(search.Category));
            }

            if (search.IsVegetarian.HasValue)
            {
                query = query.Where(m => m.IsVegetarian == search.IsVegetarian.Value);
            }

            if (search.IsVegan.HasValue)
            {
                query = query.Where(m => m.IsVegan == search.IsVegan.Value);
            }

            if (search.IsAvailable.HasValue)
            {
                query = query.Where(m => m.IsAvailable == search.IsAvailable.Value);
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(m => m.Name.Contains(search.FTS) || 
                    (m.Description != null && m.Description.Contains(search.FTS)));
            }

            return query;
        }

        protected override MenuItemResponse MapToResponse(Database.MenuItem entity)
        {
            if (entity == null)
                return null!;
                
            return new MenuItemResponse
            {
                Id = entity.Id,
                RestaurantId = entity.RestaurantId,
                RestaurantName = entity.Restaurant != null ? entity.Restaurant.Name : string.Empty,
                Name = entity.Name,
                Description = entity.Description,
                Price = entity.Price,
                Category = entity.Category,
                IsVegetarian = entity.IsVegetarian,
                IsVegan = entity.IsVegan,
                Allergens = entity.Allergens,
                ImageUrl = entity.ImageUrl,
                IsAvailable = entity.IsAvailable,
                CreatedAt = entity.CreatedAt
            };
        }
        
        public override async Task<MenuItemResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.MenuItems
                .Include(m => m.Restaurant)
                .FirstOrDefaultAsync(m => m.Id == id);
                
            if (entity == null)
                return null;
                
            return MapToResponse(entity);
        }
    }
}


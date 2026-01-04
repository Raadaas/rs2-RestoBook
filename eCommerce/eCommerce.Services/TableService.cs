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

            if (!string.IsNullOrEmpty(search.TableType))
            {
                query = query.Where(t => t.TableType != null && t.TableType.Contains(search.TableType));
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(t => t.IsActive == search.IsActive.Value);
            }

            return query;
        }

        protected override TableResponse MapToResponse(Database.Table entity)
        {
            if (entity == null)
                return null!;
                
            return new TableResponse
            {
                Id = entity.Id,
                RestaurantId = entity.RestaurantId,
                RestaurantName = entity.Restaurant != null ? entity.Restaurant.Name : string.Empty,
                TableNumber = entity.TableNumber,
                Capacity = entity.Capacity,
                PositionX = entity.PositionX,
                PositionY = entity.PositionY,
                TableType = entity.TableType,
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
    }
}


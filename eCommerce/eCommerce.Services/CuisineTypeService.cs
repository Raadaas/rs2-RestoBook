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
    public class CuisineTypeService : BaseCRUDService<CuisineTypeResponse, CuisineTypeSearchObject, Database.CuisineType, CuisineTypeUpsertRequest, CuisineTypeUpsertRequest>, ICuisineTypeService
    {
        public CuisineTypeService(eCommerceDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<Database.CuisineType> ApplyFilter(IQueryable<Database.CuisineType> query, CuisineTypeSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(ct => ct.Name.Contains(search.Name));
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(ct => ct.Name.Contains(search.FTS) || 
                    (ct.Description != null && ct.Description.Contains(search.FTS)));
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(ct => ct.IsActive == search.IsActive.Value);
            }

            return query;
        }

        protected override async Task BeforeInsert(Database.CuisineType entity, CuisineTypeUpsertRequest request)
        {
            if (await _context.CuisineTypes.AnyAsync(ct => ct.Name == request.Name))
            {
                throw new InvalidOperationException("A cuisine type with this name already exists.");
            }
        }

        protected override async Task BeforeUpdate(Database.CuisineType entity, CuisineTypeUpsertRequest request)
        {
            if (await _context.CuisineTypes.AnyAsync(ct => ct.Name == request.Name && ct.Id != entity.Id))
            {
                throw new InvalidOperationException("A cuisine type with this name already exists.");
            }
        }
    }
}


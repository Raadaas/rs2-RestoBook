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
    public class CityService : BaseCRUDService<CityResponse, CitySearchObject, Database.City, CityUpsertRequest, CityUpsertRequest>, ICityService
    {
        public CityService(eCommerceDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<Database.City> ApplyFilter(IQueryable<Database.City> query, CitySearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(c => c.Name.Contains(search.Name));
            }

            if (!string.IsNullOrEmpty(search.PostalCode))
            {
                query = query.Where(c => c.PostalCode != null && c.PostalCode.Contains(search.PostalCode));
            }

            if (!string.IsNullOrEmpty(search.Region))
            {
                query = query.Where(c => c.Region != null && c.Region.Contains(search.Region));
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(c => c.Name.Contains(search.FTS) || 
                    (c.PostalCode != null && c.PostalCode.Contains(search.FTS)) ||
                    (c.Region != null && c.Region.Contains(search.FTS)));
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(c => c.IsActive == search.IsActive.Value);
            }

            return query;
        }

        protected override async Task BeforeInsert(Database.City entity, CityUpsertRequest request)
        {
            if (await _context.Cities.AnyAsync(c => c.Name == request.Name))
            {
                throw new InvalidOperationException("A city with this name already exists.");
            }
        }

        protected override async Task BeforeUpdate(Database.City entity, CityUpsertRequest request)
        {
            if (await _context.Cities.AnyAsync(c => c.Name == request.Name && c.Id != entity.Id))
            {
                throw new InvalidOperationException("A city with this name already exists.");
            }
        }
    }
}


using eCommerce.Model;
using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using eCommerce.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace eCommerce.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CitiesController : BaseCRUDController<CityResponse, CitySearchObject, CityUpsertRequest, CityUpsertRequest>
    {
        public CitiesController(ICityService service) : base(service)
        {
        }

        [HttpGet("list")]
        [AllowAnonymous]
        public async Task<PagedResult<CityResponse>> GetList([FromQuery] CitySearchObject? search = null)
        {
            return await base.Get(search ?? new CitySearchObject());
        }
    }
}


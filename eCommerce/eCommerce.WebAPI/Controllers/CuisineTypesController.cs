using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using eCommerce.Services;
using Microsoft.AspNetCore.Mvc;

namespace eCommerce.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CuisineTypesController : BaseCRUDController<CuisineTypeResponse, CuisineTypeSearchObject, CuisineTypeUpsertRequest, CuisineTypeUpsertRequest>
    {
        public CuisineTypesController(ICuisineTypeService service) : base(service)
        {
        }
    }
}


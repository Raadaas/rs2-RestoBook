using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using eCommerce.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eCommerce.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class RestaurantWorkingHoursController : BaseCRUDController<RestaurantWorkingHoursResponse, RestaurantWorkingHoursSearchObject, RestaurantWorkingHoursUpsertRequest, RestaurantWorkingHoursUpsertRequest>
    {
        public RestaurantWorkingHoursController(IRestaurantWorkingHoursService service) : base(service)
        {
        }
    }
}


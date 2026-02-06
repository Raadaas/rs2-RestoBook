using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using eCommerce.Services;
using eCommerce.WebAPI.Attributes;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eCommerce.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [MyAuthorization(requireAdmin: true, requireClient: false)]
    public class RestaurantStatisticsController : BaseCRUDController<RestaurantStatisticResponse, RestaurantStatisticSearchObject, RestaurantStatisticUpsertRequest, RestaurantStatisticUpsertRequest>
    {
        public RestaurantStatisticsController(IRestaurantStatisticService service) : base(service)
        {
        }
    }
}


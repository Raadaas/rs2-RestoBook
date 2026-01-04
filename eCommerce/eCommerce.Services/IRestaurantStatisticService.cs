using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;

namespace eCommerce.Services
{
    public interface IRestaurantStatisticService : ICRUDService<RestaurantStatisticResponse, RestaurantStatisticSearchObject, RestaurantStatisticUpsertRequest, RestaurantStatisticUpsertRequest>
    {
    }
}


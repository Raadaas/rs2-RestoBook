using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;

namespace eCommerce.Services
{
    public interface IRestaurantService : ICRUDService<RestaurantResponse, RestaurantSearchObject, RestaurantUpsertRequest, RestaurantUpsertRequest>
    {
        Task<List<RestaurantResponse>> GetRecommendedForUserAsync(int userId, int count = 10);
    }
}


using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    public interface IRestaurantGalleryService
    {
        Task<IReadOnlyList<RestaurantGalleryResponse>> GetByRestaurantIdAsync(int restaurantId);
        Task<RestaurantGalleryResponse> InsertAsync(RestaurantGalleryInsertRequest request);
        Task DeleteAsync(int id);
    }
}

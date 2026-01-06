using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    public interface IReservationService : ICRUDService<ReservationResponse, ReservationSearchObject, ReservationUpsertRequest, ReservationUpsertRequest>
    {
        Task<object> GetTodayReservationsAsync(int? restaurantId = null);
    }
}


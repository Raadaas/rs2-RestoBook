using eCommerce.Model;
using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    public interface IReservationService : ICRUDService<ReservationResponse, ReservationSearchObject, ReservationUpsertRequest, ReservationUpsertRequest>
    {
        Task<object> GetTodayReservationsAsync(int? restaurantId = null);
        Task<object> GetAllReservationsAsync(int? restaurantId = null);
        Task<List<ReservationResponse>> GetTodayReservationsByStateAsync(ReservationState state, int? restaurantId = null);
        Task<List<ReservationResponse>> GetAllReservationsByStateAsync(ReservationState state, int? restaurantId = null);
        Task<ReservationResponse> ConfirmReservationAsync(int id);
        Task<ReservationResponse> CancelReservationAsync(int id, string? reason = null);
        Task<ReservationResponse> CompleteReservationAsync(int id);
    }
}


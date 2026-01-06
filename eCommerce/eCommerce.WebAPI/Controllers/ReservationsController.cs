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
    [Authorize]
    public class ReservationsController : BaseCRUDController<ReservationResponse, ReservationSearchObject, ReservationUpsertRequest, ReservationUpsertRequest>
    {
        private readonly IReservationService _reservationService;

        public ReservationsController(IReservationService service) : base(service)
        {
            _reservationService = service;
        }

        [HttpGet("today", Order = 1)]
        public async Task<ActionResult<object>> GetTodayReservations([FromQuery] int? restaurantId = null)
        {
            var result = await _reservationService.GetTodayReservationsAsync(restaurantId);
            return Ok(result);
        }
    }
}


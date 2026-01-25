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

        [HttpGet("all", Order = 1)]
        public async Task<ActionResult<object>> GetAllReservations([FromQuery] int? restaurantId = null)
        {
            var result = await _reservationService.GetAllReservationsAsync(restaurantId);
            return Ok(result);
        }

        [HttpGet("today/by-state", Order = 1)]
        public async Task<ActionResult<System.Collections.Generic.List<ReservationResponse>>> GetTodayReservationsByState(
            [FromQuery] ReservationState state,
            [FromQuery] int? restaurantId = null)
        {
            var result = await _reservationService.GetTodayReservationsByStateAsync(state, restaurantId);
            return Ok(result);
        }

        [HttpGet("all/by-state", Order = 1)]
        public async Task<ActionResult<System.Collections.Generic.List<ReservationResponse>>> GetAllReservationsByState(
            [FromQuery] ReservationState state,
            [FromQuery] int? restaurantId = null)
        {
            var result = await _reservationService.GetAllReservationsByStateAsync(state, restaurantId);
            return Ok(result);
        }

        [HttpPost("{id}/confirm", Order = 1)]
        public async Task<ActionResult<ReservationResponse>> ConfirmReservation(int id)
        {
            try
            {
                var result = await _reservationService.ConfirmReservationAsync(id);
                return Ok(result);
            }
            catch (System.InvalidOperationException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPost("{id}/cancel", Order = 1)]
        public async Task<ActionResult<ReservationResponse>> CancelReservation(int id, [FromBody] CancelReservationRequest? request = null)
        {
            try
            {
                var result = await _reservationService.CancelReservationAsync(id, request?.Reason);
                return Ok(result);
            }
            catch (System.InvalidOperationException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPost("{id}/complete", Order = 1)]
        public async Task<ActionResult<ReservationResponse>> CompleteReservation(int id)
        {
            try
            {
                var result = await _reservationService.CompleteReservationAsync(id);
                return Ok(result);
            }
            catch (System.InvalidOperationException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        public class CancelReservationRequest
        {
            public string? Reason { get; set; }
        }
    }
}


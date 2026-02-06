using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Services;
using eCommerce.WebAPI.Attributes;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eCommerce.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class RestaurantGalleriesController : ControllerBase
    {
        private readonly IRestaurantGalleryService _service;

        public RestaurantGalleriesController(IRestaurantGalleryService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<ActionResult<IReadOnlyList<RestaurantGalleryResponse>>> GetByRestaurant([FromQuery] int restaurantId)
        {
            var list = await _service.GetByRestaurantIdAsync(restaurantId);
            return Ok(list);
        }

        [HttpPost]
        [MyAuthorization(requireAdmin: true, requireClient: false)]
        public async Task<ActionResult<RestaurantGalleryResponse>> Insert([FromBody] RestaurantGalleryInsertRequest request)
        {
            var result = await _service.InsertAsync(request);
            return Ok(result);
        }

        [HttpDelete("{id:int}")]
        [MyAuthorization(requireAdmin: true, requireClient: false)]
        public async Task<IActionResult> Delete(int id)
        {
            try
            {
                await _service.DeleteAsync(id);
                return Ok();
            }
            catch (InvalidOperationException ex)
            {
                return NotFound(new { message = ex.Message });
            }
        }
    }
}

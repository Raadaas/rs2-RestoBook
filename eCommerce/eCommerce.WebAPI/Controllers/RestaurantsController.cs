using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using eCommerce.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;

namespace eCommerce.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RestaurantsController : BaseCRUDController<RestaurantResponse, RestaurantSearchObject, RestaurantUpsertRequest, RestaurantUpsertRequest>
    {
        private readonly IRestaurantService _restaurantService;

        public RestaurantsController(IRestaurantService service) : base(service)
        {
            _restaurantService = service;
        }

        /// <summary>
        /// Get recommended restaurants for the current user (content-based: TF-IDF + cosine similarity). Requires authentication.
        /// </summary>
        [HttpGet("recommended")]
        [Authorize]
        public async Task<ActionResult<List<RestaurantResponse>>> GetRecommended([FromQuery] int count = 10)
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();
            var list = await _restaurantService.GetRecommendedForUserAsync(userId.Value, Math.Clamp(count, 1, 50));
            return Ok(list);
        }

        private int? GetCurrentUserId()
        {
            var idStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(idStr) || !int.TryParse(idStr, out var id)) return null;
            return id;
        }
    }
}


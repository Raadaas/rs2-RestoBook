using System;
using System.Text.Json.Serialization;
using eCommerce.Model.Responses;
using eCommerce.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using System.Threading.Tasks;

namespace eCommerce.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class LoyaltyController : ControllerBase
    {
        private readonly ILoyaltyService _loyaltyService;

        public LoyaltyController(ILoyaltyService loyaltyService)
        {
            _loyaltyService = loyaltyService;
        }

        [HttpGet("points")]
        public async Task<ActionResult<LoyaltyPointsResponse>> GetMyPoints()
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId))
                return Unauthorized();

            var (currentPoints, totalPointsEarned) = await _loyaltyService.GetPointsForUserAsync(userId);
            return Ok(new LoyaltyPointsResponse
            {
                CurrentPoints = currentPoints,
                TotalPointsEarned = totalPointsEarned
            });
        }

        /// <summary>
        /// Get available rewards. Optionally filter by restaurantId (rewards for that restaurant + global).
        /// </summary>
        [HttpGet("rewards")]
        public async Task<ActionResult<IReadOnlyList<RewardResponse>>> GetAvailableRewards([FromQuery] int? restaurantId = null)
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId))
                return Unauthorized();

            var rewards = await _loyaltyService.GetAvailableRewardsAsync(userId, restaurantId);
            return Ok(rewards);
        }

        /// <summary>
        /// Redeem a reward. Deducts points and creates a UserReward.
        /// </summary>
        [HttpPost("rewards/{rewardId:int}/redeem")]
        public async Task<ActionResult<UserRewardResponse>> RedeemReward(int rewardId)
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId))
                return Unauthorized();

            try
            {
                var userReward = await _loyaltyService.RedeemRewardAsync(userId, rewardId);
                return Ok(userReward);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Get all rewards redeemed by the current user.
        /// </summary>
        [HttpGet("my-rewards")]
        public async Task<ActionResult<IReadOnlyList<UserRewardResponse>>> GetMyRedeemedRewards()
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdStr) || !int.TryParse(userIdStr, out var userId))
                return Unauthorized();

            var list = await _loyaltyService.GetMyRedeemedRewardsAsync(userId);
            return Ok(list);
        }

        public class LoyaltyPointsResponse
        {
            [JsonPropertyName("currentPoints")]
            public int CurrentPoints { get; set; }
            [JsonPropertyName("totalPointsEarned")]
            public int TotalPointsEarned { get; set; }
        }
    }
}

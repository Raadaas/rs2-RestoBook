using eCommerce.Model.Responses;
using eCommerce.Services.Database;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    public interface ILoyaltyService
    {
        /// <summary>
        /// Adds 10 loyalty points for a completed reservation. Idempotent: no-op if points were already added for this reservation.
        /// Caller is responsible for SaveChanges.
        /// </summary>
        Task AddPointsForCompletedReservationAsync(Database.Reservation reservation);

        /// <summary>
        /// Returns current and total earned points for the user, or (0, 0) if no LoyaltyPoint exists.
        /// </summary>
        Task<(int CurrentPoints, int TotalPointsEarned)> GetPointsForUserAsync(int userId);

        /// <summary>
        /// Returns available rewards (active). If restaurantId is set, returns global rewards plus rewards for that restaurant.
        /// CanRedeem is set based on user's current points.
        /// </summary>
        Task<IReadOnlyList<RewardResponse>> GetAvailableRewardsAsync(int userId, int? restaurantId = null);

        /// <summary>
        /// Redeems a reward for the user. Deducts points, creates UserReward and negative PointsTransaction.
        /// Throws InvalidOperationException if reward not found, inactive, or insufficient points.
        /// </summary>
        Task<UserRewardResponse> RedeemRewardAsync(int userId, int rewardId);

        /// <summary>
        /// Returns all rewards redeemed by the user.
        /// </summary>
        Task<IReadOnlyList<UserRewardResponse>> GetMyRedeemedRewardsAsync(int userId);
    }
}

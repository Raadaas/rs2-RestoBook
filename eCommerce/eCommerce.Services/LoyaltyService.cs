using eCommerce.Model;
using eCommerce.Model.Responses;
using eCommerce.Services.Database;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    public class LoyaltyService : ILoyaltyService
    {
        private const int PointsPerCompletedReservation = 10;
        private readonly eCommerceDbContext _context;

        public LoyaltyService(eCommerceDbContext context)
        {
            _context = context;
        }

        public async Task AddPointsForCompletedReservationAsync(Database.Reservation reservation)
        {
            if (reservation.State != eCommerce.Model.ReservationState.Completed)
                return;

            var existing = await _context.PointsTransactions
                .AnyAsync(t => t.ReservationId == reservation.Id);
            if (existing)
                return;

            var lp = await _context.LoyaltyPoints
                .FirstOrDefaultAsync(x => x.UserId == reservation.UserId);
            if (lp == null)
            {
                lp = new LoyaltyPoint
                {
                    UserId = reservation.UserId,
                    CurrentPoints = 0,
                    TotalPointsEarned = 0,
                    LastUpdated = System.DateTime.UtcNow
                };
                _context.LoyaltyPoints.Add(lp);
                await _context.SaveChangesAsync();
            }

            var tx = new PointsTransaction
            {
                UserId = reservation.UserId,
                LoyaltyPointId = lp.Id,
                ReservationId = reservation.Id,
                Points = PointsPerCompletedReservation,
                Description = "Completed reservation",
                CreatedAt = System.DateTime.UtcNow
            };
            _context.PointsTransactions.Add(tx);

            lp.CurrentPoints += PointsPerCompletedReservation;
            lp.TotalPointsEarned += PointsPerCompletedReservation;
            lp.LastUpdated = System.DateTime.UtcNow;
        }

        public async Task<(int CurrentPoints, int TotalPointsEarned)> GetPointsForUserAsync(int userId)
        {
            try
            {
                await EnsurePointsForCompletedReservationsAsync(userId);
            }
            catch
            {
                /* backfill failed; continue to return whatever points we have */
            }

            var lp = await _context.LoyaltyPoints
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.UserId == userId);
            if (lp == null)
                return (0, 0);

            var currentPoints = await GetEffectiveCurrentPointsAsync(userId, lp);
            return (currentPoints, lp.TotalPointsEarned);
        }

        /// <summary>
        /// Credits points for any completed reservations that don't yet have a PointsTransaction (e.g. completed before loyalty was implemented).
        /// </summary>
        private async Task EnsurePointsForCompletedReservationsAsync(int userId)
        {
            var completed = await _context.Reservations
                .Where(r => r.UserId == userId && r.State == ReservationState.Completed)
                .ToListAsync();

            foreach (var r in completed)
            {
                await AddPointsForCompletedReservationAsync(r);
            }

            await _context.SaveChangesAsync();
        }

        private async Task<int> GetEffectiveCurrentPointsAsync(int userId, LoyaltyPoint lp)
        {
            var currentPoints = lp.CurrentPoints;
            // Fix legacy data: if CurrentPoints is 0 but TotalPointsEarned > 0 and user never redeemed, treat as data inconsistency
            if (currentPoints == 0 && lp.TotalPointsEarned > 0)
            {
                var hasRedemptions = await _context.PointsTransactions
                    .AnyAsync(t => t.UserId == userId && t.Points < 0);
                if (!hasRedemptions)
                    currentPoints = lp.TotalPointsEarned;
            }
            return currentPoints;
        }

        public async Task<IReadOnlyList<RewardResponse>> GetAvailableRewardsAsync(int userId, int? restaurantId = null)
        {
            var currentPoints = 0;
            var lp = await _context.LoyaltyPoints
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.UserId == userId);
            if (lp != null)
                currentPoints = await GetEffectiveCurrentPointsAsync(userId, lp);

            var query = _context.Rewards
                .AsNoTracking()
                .Where(r => r.IsActive);

            if (restaurantId.HasValue)
                query = query.Where(r => r.RestaurantId == restaurantId.Value);

            var rewards = await query
                .OrderBy(r => r.PointsRequired)
                .ToListAsync();

            return rewards
                .Select(r => new RewardResponse
                {
                    Id = r.Id,
                    Title = r.Title,
                    Description = r.Description,
                    PointsRequired = r.PointsRequired,
                    RestaurantId = r.RestaurantId,
                    IsActive = r.IsActive,
                    CreatedAt = r.CreatedAt,
                    TimesClaimed = 0,
                    CanRedeem = currentPoints >= r.PointsRequired
                })
                .ToList();
        }

        public async Task<UserRewardResponse> RedeemRewardAsync(int userId, int rewardId)
        {
            var reward = await _context.Rewards.FindAsync(rewardId);
            if (reward == null)
                throw new InvalidOperationException("Reward not found.");
            if (!reward.IsActive)
                throw new InvalidOperationException("Reward is no longer available.");

            var lp = await _context.LoyaltyPoints.FirstOrDefaultAsync(x => x.UserId == userId);
            if (lp == null || lp.CurrentPoints < reward.PointsRequired)
                throw new InvalidOperationException("Insufficient loyalty points.");

            lp.CurrentPoints -= reward.PointsRequired;
            lp.LastUpdated = DateTime.UtcNow;

            var tx = new PointsTransaction
            {
                UserId = userId,
                LoyaltyPointId = lp.Id,
                Points = -reward.PointsRequired,
                Description = $"Redeemed: {reward.Title}",
                CreatedAt = DateTime.UtcNow
            };
            _context.PointsTransactions.Add(tx);

            var expiresAt = DateTime.UtcNow.AddDays(30);
            var userReward = new UserReward
            {
                UserId = userId,
                RewardId = reward.Id,
                RedeemedAt = DateTime.UtcNow,
                ExpiresAt = expiresAt,
                IsUsed = false
            };
            _context.UserRewards.Add(userReward);

            await _context.SaveChangesAsync();

            return new UserRewardResponse
            {
                Id = userReward.Id,
                RewardId = reward.Id,
                RewardTitle = reward.Title,
                RewardDescription = reward.Description,
                PointsRequired = reward.PointsRequired,
                RedeemedAt = userReward.RedeemedAt,
                ExpiresAt = userReward.ExpiresAt,
                IsUsed = userReward.IsUsed,
                UsedAt = userReward.UsedAt
            };
        }

        public async Task<IReadOnlyList<UserRewardResponse>> GetMyRedeemedRewardsAsync(int userId)
        {
            var list = await _context.UserRewards
                .AsNoTracking()
                .Where(ur => ur.UserId == userId)
                .Include(ur => ur.Reward)
                .OrderByDescending(ur => ur.RedeemedAt)
                .ToListAsync();

            return list
                .Select(ur => new UserRewardResponse
                {
                    Id = ur.Id,
                    RewardId = ur.RewardId,
                    RewardTitle = ur.Reward.Title,
                    RewardDescription = ur.Reward.Description,
                    PointsRequired = ur.Reward.PointsRequired,
                    RedeemedAt = ur.RedeemedAt,
                    ExpiresAt = ur.ExpiresAt,
                    IsUsed = ur.IsUsed,
                    UsedAt = ur.UsedAt
                })
                .ToList();
        }
    }
}

using System;

namespace eCommerce.Model.Responses
{
    public class UserRewardResponse
    {
        public int Id { get; set; }
        public int RewardId { get; set; }
        public string RewardTitle { get; set; } = string.Empty;
        public string? RewardDescription { get; set; }
        public int PointsRequired { get; set; }
        public DateTime RedeemedAt { get; set; }
        public DateTime? ExpiresAt { get; set; }
        public bool IsUsed { get; set; }
        public DateTime? UsedAt { get; set; }
    }
}

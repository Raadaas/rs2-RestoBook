using System;

namespace eCommerce.Model.Responses
{
    public class RewardResponse
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int PointsRequired { get; set; }
        public int? RestaurantId { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public int TimesClaimed { get; set; }
        public bool CanRedeem { get; set; }
    }
}

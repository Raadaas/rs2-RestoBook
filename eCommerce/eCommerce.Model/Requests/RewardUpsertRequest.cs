using System;
using System.ComponentModel.DataAnnotations;

namespace eCommerce.Model.Requests
{
    public class RewardUpsertRequest
    {
        [Required]
        [MaxLength(100)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(500)]
        public string? Description { get; set; }

        public int PointsRequired { get; set; }

        public int? RestaurantId { get; set; }

        public bool IsActive { get; set; } = true;
    }
}

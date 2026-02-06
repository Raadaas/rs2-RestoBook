using System;
using System.ComponentModel.DataAnnotations;

namespace eCommerce.Model.Requests
{
    public class RewardUpsertRequest
    {
        [Required(ErrorMessage = "Reward title is required.")]
        [MaxLength(100, ErrorMessage = "Title must not exceed 100 characters.")]
        public string Title { get; set; } = string.Empty;

        [MaxLength(500, ErrorMessage = "Description must not exceed 500 characters.")]
        public string? Description { get; set; }

        [Range(0, 1000000, ErrorMessage = "Points required must be 0 or greater.")]
        public int PointsRequired { get; set; }

        public int? RestaurantId { get; set; }

        public bool IsActive { get; set; } = true;
    }
}

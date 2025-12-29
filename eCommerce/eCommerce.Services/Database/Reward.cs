using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Services.Database
{
    public class Reward
    {
        [Key]
        public int Id { get; set; }
        
        public int? RestaurantId { get; set; }
        
        [ForeignKey("RestaurantId")]
        public Restaurant? Restaurant { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string Title { get; set; } = string.Empty;
        
        [MaxLength(500)]
        public string? Description { get; set; }
        
        public int PointsRequired { get; set; }
        
        [MaxLength(50)]
        public string? RewardType { get; set; }
        
        public bool IsActive { get; set; } = true;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        public ICollection<UserReward> UserRewards { get; set; } = new List<UserReward>();
    }
}


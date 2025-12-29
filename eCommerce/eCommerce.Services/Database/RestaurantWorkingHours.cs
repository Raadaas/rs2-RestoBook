using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Services.Database
{
    public class RestaurantWorkingHours
    {
        [Key]
        public int Id { get; set; }
        
        public int RestaurantId { get; set; }
        
        [ForeignKey("RestaurantId")]
        public Restaurant Restaurant { get; set; } = null!;
        
        public int DayOfWeek { get; set; }
        
        public TimeSpan OpenTime { get; set; }
        
        public TimeSpan CloseTime { get; set; }
        
        public bool IsClosed { get; set; } = false;
    }
}


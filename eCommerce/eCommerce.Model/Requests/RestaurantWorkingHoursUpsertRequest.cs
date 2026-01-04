using System;
using System.ComponentModel.DataAnnotations;

namespace eCommerce.Model.Requests
{
    public class RestaurantWorkingHoursUpsertRequest
    {
        [Required]
        public int RestaurantId { get; set; }
        
        [Required]
        public int DayOfWeek { get; set; }
        
        [Required]
        public TimeSpan OpenTime { get; set; }
        
        [Required]
        public TimeSpan CloseTime { get; set; }
        
        public bool IsClosed { get; set; } = false;
    }
}


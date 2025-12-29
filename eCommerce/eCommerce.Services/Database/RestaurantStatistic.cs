using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Services.Database
{
    public class RestaurantStatistic
    {
        [Key]
        public int Id { get; set; }
        
        public int RestaurantId { get; set; }
        
        [ForeignKey("RestaurantId")]
        public Restaurant Restaurant { get; set; } = null!;
        
        public DateTime Date { get; set; }
        
        public int TotalReservations { get; set; } = 0;
        
        public int CompletedReservations { get; set; } = 0;
        
        public int CancelledReservations { get; set; } = 0;
        
        public int NoShows { get; set; } = 0;
        
        [Column(TypeName = "decimal(5,2)")]
        public decimal? AverageOccupancy { get; set; }
        
        public TimeSpan? PeakHour { get; set; }
        
        [Column(TypeName = "decimal(10,2)")]
        public decimal? Revenue { get; set; }
    }
}


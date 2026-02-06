using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Model.Requests
{
    public class RestaurantStatisticUpsertRequest
    {
        [Required(ErrorMessage = "Restaurant ID is required.")]
        public int RestaurantId { get; set; }
        
        [Required(ErrorMessage = "Date is required.")]
        public DateTime Date { get; set; }
        
        [Range(0, int.MaxValue, ErrorMessage = "Total reservations must be 0 or greater.")]
        public int TotalReservations { get; set; } = 0;
        
        [Range(0, int.MaxValue, ErrorMessage = "Completed reservations must be 0 or greater.")]
        public int CompletedReservations { get; set; } = 0;
        
        [Range(0, int.MaxValue, ErrorMessage = "Cancelled reservations must be 0 or greater.")]
        public int CancelledReservations { get; set; } = 0;
        
        [Range(0, int.MaxValue, ErrorMessage = "No-shows must be 0 or greater.")]
        public int NoShows { get; set; } = 0;
        
        [Range(0, 100, ErrorMessage = "Average occupancy must be between 0 and 100.")]
        [Column(TypeName = "decimal(5,2)")]
        public decimal? AverageOccupancy { get; set; }
        
        public TimeSpan? PeakHour { get; set; }
        
        [Range(0, double.MaxValue, ErrorMessage = "Revenue must be 0 or greater.")]
        [Column(TypeName = "decimal(10,2)")]
        public decimal? Revenue { get; set; }
    }
}


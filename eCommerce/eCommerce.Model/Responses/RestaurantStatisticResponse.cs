using System;

namespace eCommerce.Model.Responses
{
    public class RestaurantStatisticResponse
    {
        public int Id { get; set; }
        public int RestaurantId { get; set; }
        public string RestaurantName { get; set; } = string.Empty;
        public DateTime Date { get; set; }
        public int TotalReservations { get; set; }
        public int CompletedReservations { get; set; }
        public int CancelledReservations { get; set; }
        public int NoShows { get; set; }
        public decimal? AverageOccupancy { get; set; }
        public TimeSpan? PeakHour { get; set; }
        public decimal? Revenue { get; set; }
    }
}


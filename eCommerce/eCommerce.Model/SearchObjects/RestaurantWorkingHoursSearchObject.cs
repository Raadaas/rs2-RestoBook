namespace eCommerce.Model.SearchObjects
{
    public class RestaurantWorkingHoursSearchObject : BaseSearchObject
    {
        public int? RestaurantId { get; set; }
        public int? DayOfWeek { get; set; }
        public bool? IsClosed { get; set; }
    }
}


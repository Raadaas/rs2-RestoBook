using System;

namespace eCommerce.Model.SearchObjects
{
    public class RestaurantStatisticSearchObject : BaseSearchObject
    {
        public int? RestaurantId { get; set; }
        public DateTime? DateFrom { get; set; }
        public DateTime? DateTo { get; set; }
    }
}


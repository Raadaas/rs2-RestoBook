using System;

namespace eCommerce.Model.SearchObjects
{
    public class SpecialOfferSearchObject : BaseSearchObject
    {
        public int? RestaurantId { get; set; }
        public string? Title { get; set; }
        public bool? IsActive { get; set; }
        public DateTime? ValidFrom { get; set; }
        public DateTime? ValidTo { get; set; }
    }
}


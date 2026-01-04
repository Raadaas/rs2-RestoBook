namespace eCommerce.Model.SearchObjects
{
    public class MenuItemSearchObject : BaseSearchObject
    {
        public int? RestaurantId { get; set; }
        public string? Name { get; set; }
        public string? Category { get; set; }
        public bool? IsVegetarian { get; set; }
        public bool? IsVegan { get; set; }
        public bool? IsAvailable { get; set; }
    }
}


using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using eCommerce.Services;
using Microsoft.AspNetCore.Mvc;

namespace eCommerce.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MenuItemsController : BaseCRUDController<MenuItemResponse, MenuItemSearchObject, MenuItemUpsertRequest, MenuItemUpsertRequest>
    {
        public MenuItemsController(IMenuItemService service) : base(service)
        {
        }
    }
}


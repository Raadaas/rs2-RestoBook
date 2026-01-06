using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using eCommerce.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace eCommerce.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class TablesController : BaseCRUDController<TableResponse, TableSearchObject, TableUpsertRequest, TableUpsertRequest>
    {
        private readonly ITableService _tableService;

        public TablesController(ITableService service) : base(service)
        {
            _tableService = service;
        }

        [HttpGet("occupancy", Order = 1)]
        public async Task<ActionResult<object>> GetOccupancy([FromQuery] int? restaurantId = null)
        {
            var result = await _tableService.GetOccupancyAsync(restaurantId);
            return Ok(result);
        }
    }
}


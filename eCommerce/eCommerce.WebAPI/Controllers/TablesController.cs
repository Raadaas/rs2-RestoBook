using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using eCommerce.Services;
using eCommerce.WebAPI.Attributes;
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
        [MyAuthorization(requireAdmin: true, requireClient: false)]
        public async Task<ActionResult<object>> GetOccupancy([FromQuery] int? restaurantId = null)
        {
            var result = await _tableService.GetOccupancyAsync(restaurantId);
            return Ok(result);
        }

        [HttpPost]
        [MyAuthorization(requireAdmin: true, requireClient: false)]
        public override async Task<TableResponse> Create([FromBody] TableUpsertRequest request)
        {
            return await base.Create(request);
        }

        [HttpPut("{id:int}")]
        [MyAuthorization(requireAdmin: true, requireClient: false)]
        public override async Task<TableResponse?> Update(int id, [FromBody] TableUpsertRequest request)
        {
            return await base.Update(id, request);
        }

        [HttpDelete("{id:int}")]
        [MyAuthorization(requireAdmin: true, requireClient: false)]
        public override async Task<bool> Delete(int id)
        {
            return await base.Delete(id);
        }
    }
}


using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BE1.Migrations
{
    /// <inheritdoc />
    public partial class AddTotpSupport : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsTotpEnabled",
                table: "AspNetUsers",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "TotpSecretKey",
                table: "AspNetUsers",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsTotpEnabled",
                table: "AspNetUsers");

            migrationBuilder.DropColumn(
                name: "TotpSecretKey",
                table: "AspNetUsers");
        }
    }
}

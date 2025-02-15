#!/bin/bash

# Output file
output_file="tgw_routes.csv"

# Write header to CSV file
echo "CIDR,AttachmentID,RouteTableName" > $output_file

# Get all TGW route table IDs and names
tgw_route_tables=$(aws ec2 describe-transit-gateway-route-tables --query "TransitGatewayRouteTables[*].{ID:TransitGatewayRouteTableId,Name:Tags[?Key=='Name'].Value | [0]}" --output json)

# Debug: Print the TGW route tables JSON
echo "TGW Route Tables: $tgw_route_tables"

# Loop through each TGW route table using jq and a while loop
echo "$tgw_route_tables" | jq -c '.[]' | while read -r tgw_route_table; do
    tgw_route_table_id=$(echo $tgw_route_table | jq -r '.ID')
    tgw_route_table_name=$(echo $tgw_route_table | jq -r '.Name')

    # Debug: Print the current TGW route table ID and Name
    echo "Processing TGW Route Table ID: $tgw_route_table_id, Name: $tgw_route_table_name"

    # Get routes for the current TGW route table
    routes=$(aws ec2 search-transit-gateway-routes --transit-gateway-route-table-id $tgw_route_table_id --filters Name=type,Values=static,propagated --query "Routes[*].{CIDR:DestinationCidrBlock,Attachments:TransitGatewayAttachments[*].TransitGatewayAttachmentId}" --output json)

    # Debug: Print the routes JSON
    echo "Routes for TGW Route Table ID $tgw_route_table_id: $routes"

    # Loop through each route and append to CSV
    echo "$routes" | jq -c '.[]' | while read -r route; do
        cidr=$(echo $route | jq -r '.CIDR')
        attachments=$(echo $route | jq -r '.Attachments | join(",")')
        echo "$cidr,$attachments,$tgw_route_table_name" >> $output_file
    done
done

echo "Routes exported to $output_file"

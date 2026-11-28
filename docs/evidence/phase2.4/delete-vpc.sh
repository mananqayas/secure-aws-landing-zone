#!/usr/bin/env bash
set -Eeuo pipefail

error() {
	echo "Error: $1" >&2
	exit 1
}
info() {
	{
		echo "=================="
		echo "[INFO]: $1"
	} >&2
}
info "Authenticating to AWS account..."
if ! IDENTITY=$(aws sts get-caller-identity --profile "${AWS_PROFILE:-default}" 2>&1); then
	error "AWS authentication failed: $IDENTITY"
fi

ACCOUNT_ID=$(jq -r '.Account' <<<"$IDENTITY")
info "Authenticated successfully: AWS Account ID $ACCOUNT_ID"

get_default_vpc() {
	info "Fetching default VPC.."
	local default_vpc
	if ! default_vpc=$(aws ec2 describe-vpcs \
		--filters "Name=isDefault,Values=true" \
		--query "Vpcs[0]" 2>&1); then
		error "Cannot get default VPC: $default_vpc"
	fi

	if [[ "$default_vpc" == "null" ]]; then
		error "No default VPC found in this region."
	fi

	local vpc_id
	vpc_id=$(jq -r '.VpcId' <<<"$default_vpc")
	info "VPC ID is $vpc_id"

	# Fetch instances
	instances=$(get_ec2_instances "$vpc_id")
	instance_count=$(jq 'length' <<<"$instances")
	if [[ "$instance_count" -eq 0 ]]; then
		info "No instances found"
	else
		info "Found $instance_count instances: $instances"
	fi

	# Interfaces
	interfaces=$(get_network_interfaces "vpc_id")
	interfaces_count=$(jq -r 'length' <<<"$interfaces")

	if [[ "$interfaces_count" -eq 0 ]]; then
		info "No ENIs found"
	else
		info "Found $interfaces_count ENIs: $interfaces"
	fi

	# VPC Endpoints
	vpc_endpoints=$(get_vpc_endpoints $vpc_id)
	vpc_endpoints_count=$(jq -r 'length' <<<"$vpc_endpoints")
	if [[ "$vpc_endpoints_count" -eq 0 ]]; then
		info "No VPC endpoints found"
	else
		info "Found $vpc_endpoints_count VPC endpoints: $vpc_endpoints"
	fi

	# IGW
	igws=$(detach_and_delete_igw "$vpc_id")
	echo "$igws"

	# Subnets
	subnets=$(delete_subnets "$vpc_id")
	echo "$subnets"

	# Delete VPC
	info "Deleting VPC now..."
	delete_vpc "$vpc_id"

}

get_ec2_instances() {
	info "Fetching instances reservations in VPC with ID $1"
	local instances
	if ! instances=$(
		aws ec2 describe-instances \
			--filters "Name=vpc-id,Values=$1" \
			--query "Reservations[].Instances[]" 2>&1
	); then
		error "Cannot get instances: $instances"
	fi
	echo "$instances"

}

get_network_interfaces() {

	info "Fetching ENIs..."
	local interfaces
	if ! interfaces=$(
		aws ec2 describe-network-interfaces \
			--filter "Name=vpc-id,Values=$1" \
			--query "NetworkInterfaces[]" 2>&1
	); then
		error "Cannot get ENIs: $interfaces"
	fi

	echo "$interfaces"
}

get_vpc_endpoints() {
	info "Fetching VPC endpoints.."
	local vpc_endpoints
	if ! vpc_endpoints=$(
		aws ec2 describe-vpc-endpoints \
			--filters "Name=vpc-id,Values=$1" \
			--query "VpcEndpoints[]" 2>&1
	); then
		error "Cannot get VPC endpoints: $instances"
	fi

	echo "$vpc_endpoints"
}

detach_and_delete_igw() {
	info "Detaching and deleting IGW from default VPC"
	local vpc_id="$1"
	if ! igws_response=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc_id" --query "InternetGateways[]" 2>&1); then
		error "Cannot get IGW: $igws_response"
	else
		igw_count=$(jq 'length' <<<"$igws_response")
		if [[ "$igw_count" -eq 0 ]]; then
			echo "There is no IGW attached to this VPC with ID: $vpc_id"
			echo "Continuing..."
		else
			local gw_id=$(jq -r '.[0].InternetGatewayId' <<<"$igws_response")
			info "Detaching internet gateway with Id: $gw_id"
			local gw_detach_response
			if ! gw_detach_response=$(aws ec2 detach-internet-gateway --internet-gateway-id "$gw_id" --vpc-id "$vpc_id" 2>&1); then
				error "Cannot detach IGW: $gw_detach_response"
			else
				echo "IGW: $gw_id detached successfully"
				echo "Now deleting it..."
				local deleted
				if ! deleted=$(aws ec2 delete-internet-gateway --internet-gateway-id "$gw_id" 2>&1); then
					error "Cannot delete internet gateway: $deleted"
				else
					echo "Deleted IGW: $gw_id"
				fi
			fi

		fi
	fi

}

delete_subnets() {
	local vpc_id="$1"
	info "Fetching subnets for $vpc_id"
	local subnets
	if ! subnets=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query "Subnets[]" 2>&1); then
		error "Cannot get subnets: $subnets"
	else
		local count=$(jq -r 'length' <<<"$subnets")
		if [[ "$count" -eq 0 ]]; then
			echo "No subnets created for VPC: $vpc_id"
		else
			for s in $(jq -r '.[].SubnetId' <<<"$subnets"); do
				delete_subnet "$s"
			done
		fi

	fi
}
delete_subnet() {
	local subnet_id="$1"
	echo "Deleting subnet: $subnet_id..."
	local is_deleted
	if ! is_deleted=$(aws ec2 delete-subnet --subnet-id "$subnet_id" 2>&1); then
		error "Cannot delete subnet: $subnet_id"
	else
		echo "Deleted subnet $subnet_id"
	fi
}
delete_vpc() {
	local vpc_id="$1"
	local deleted
	if ! deleted=$(aws ec2 delete-vpc --vpc-id "$vpc_id" 2>&1); then
		error "Cannot delete vpc: $deleted"
	else
		echo "VPC: $vpc_id deleted successfully"
	fi
}
get_default_vpc

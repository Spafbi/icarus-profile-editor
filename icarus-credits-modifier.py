from datetime import datetime
from glob import glob
from os.path import basename, dirname
from pathlib import Path
import argparse
import json
import logging
import os
import psutil
import shutil
import sys


def backup_profiles(profiles):
    if profiles:
        this_message = "Beginning profile backups."
        print_and_log([this_message])

    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    for profile in profiles:
        this_dir = dirname(profile)
        this_file = basename(profile)
        backup = Path(f"{this_dir}/.{this_file}.{timestamp}")
        logging.debug(f"Copying {profile} to {backup}")
        shutil.copy(profile, backup)


def get_profiles(this_path):
    profiles = list()
    for dirpath, dirnames, filenames in os.walk(this_path):
        for filename in filenames:
            if filename.lower() == "profile.json":
                # Found a profiles.json file, add its path to the list
                profiles.append(os.path.join(dirpath, filename))
    return profiles


def get_single_profile(this_path, SteamID64="0"):
    profiles = []
    if f"{SteamID64}" == "0":
        return profiles

    profile_path = Path(f"{this_path}/{SteamID64}/Profile.json")

    if os.path.isfile(profile_path):
        profiles.append(profile_path)

    return profiles


def icarus_running():
    for process in psutil.process_iter():
        if process.name().lower() == "icarus-win64-shipping.exe":
            return True
    return False


def modify_profile(profile_path, values):
    if not os.path.isfile(profile_path):
        return

    logging.debug(f"Reading: {profile_path}")

    with open(profile_path) as f:
        data = json.load(f)

    data["MetaResources"] = values

    logging.debug(f"Updating {profile_path} with new values")
    with open(profile_path, "w") as f:
        json.dump(data, f, indent=4)


def modify_profiles(profiles, values):
    for profile in profiles:
        modify_profile(profile, values)


def print_and_log(messages):
    for message in messages:
        logging.info(message)


def main():
    """
    Summary: Default method if this modules is run as __main__.
    """

    # Grab our user's profile
    localappdata = os.environ.get("localappdata")
    icarus_player_data = f"{localappdata}/Icarus/Saved/PlayerData"
    icarus_player_data_path = Path(icarus_player_data)

    # Just grabbing this script's filename
    prog = basename(__file__)
    description = f"{prog} sets credits and exotics to 9999, and talent refund points to 30, for all Steam accounts located in {icarus_player_data_path}."

    # Set up argparse to help people use this as a CLI utility
    parser = argparse.ArgumentParser(prog=prog, description=description)

    parser.add_argument(
        "-c",
        "--credits",
        type=int,
        required=False,
        help="The amount of credits you want to have in game",
        default=9999,
    )

    parser.add_argument(
        "-e",
        "--exotics",
        type=int,
        required=False,
        help="The amount of exotics you want to have in game",
        default=9999,
    )

    parser.add_argument(
        "-r",
        "--refund",
        type=int,
        required=False,
        help="The number of talent refund credits you want to have",
        default=30,
    )

    parser.add_argument(
        "-s",
        "--steam",
        type=str,
        required=False,
        help=f"This option may be specified to alter a single account, identified by its SteamID64, for which you wish to set values. Omitting this option defaults to all SteamID64 accounts in {icarus_player_data_path}",
        default="0",
    )

    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        required=False,
        help="""Verbose logging""",
    )

    # Parse our arguments!
    args = parser.parse_args()

    # This just grabs our script's path for reuse
    script_path = os.path.abspath(os.path.dirname(sys.argv[0]))

    # Check for files to trigger debug logging
    verbose = True if len(glob(str(Path(f"{script_path}/debug*")))) else False

    # Enable either INFO or DEBUG logging
    icarus_credit_mondifier = logging.getLogger()
    output_file_handler = logging.FileHandler(
        Path(f"{script_path}/icarus-credit-modifier.log")
    )
    stdout_handler = logging.StreamHandler(sys.stdout)
    icarus_credit_mondifier.addHandler(output_file_handler)
    icarus_credit_mondifier.addHandler(stdout_handler)

    if verbose or args.verbose:
        icarus_credit_mondifier.setLevel(logging.DEBUG)
    else:
        icarus_credit_mondifier.setLevel(logging.INFO)

    # Exit if Icarus isn't running
    if not icarus_running():
        these_messages = [
            "Icarus does not appear to be running.",
            "Make sure Icarus is running and at the title screen when running this utility.",
        ]
        print_and_log(these_messages)
        exit()

    # Create a list of Profiles to alter
    steam_id = f"{args.steam}".lower()
    if not steam_id == "0":
        profiles = get_single_profile(icarus_player_data_path, steam_id)
    else:
        profiles = get_profiles(icarus_player_data_path)

    if not profiles:
        messages = [
            f"No Profile.json files were found below {icarus_player_data_path}",
            "No changes have been made.",
        ]
        print_and_log(messages)
        print("Press ENTER/RETURN to continue...")
        input()
        exit()

    logging.debug("Profiles found:")
    for profile in profiles:
        logging.debug(f" {profile}")

    backup_profiles(profiles)

    values = [
        {"Count": args.credits, "MetaRow": "Credits"},
        {"Count": args.exotics, "MetaRow": "Exotic1"},
        {"Count": args.refund, "MetaRow": "Refund"},
    ]

    logging.debug(values)

    modify_profiles(profiles, values)

    this_message = "Script execution has completed. Load up a character and enjoy! Run as many times as you like."
    print_and_log([this_message])

    print("Press ENTER/RETURN to continue...")
    input()


if __name__ == "__main__":
    main()

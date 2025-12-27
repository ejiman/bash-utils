#!/usr/bin/env bash

ARGS=()
POSITIONAL=()

# ========= Argument definitions =========
# arg_flag VAR -v --verbose "desc"
# arg_value VAR -o --output "desc" "META"
# arg_value_required VAR -o --output "desc" "META"

arg_flag() {
  ARGS+=("flag|$1|$2|$3|$4|optional")
}

arg_value() {
  ARGS+=("value|$1|$2|$3|$4|$5|optional")
}

arg_value_required() {
  ARGS+=("value|$1|$2|$3|$4|$5|required")
}

# ========= Show help =========
argparse_help() {
  echo "$CLI_NAME - $CLI_DESCRIPTION"
  echo
  echo "Usage:"
  echo "  $CLI_USAGE"
  echo
  echo "Options:"
  for spec in "${ARGS[@]}"; do
    IFS='|' read -r type var short long desc meta req <<< "$spec"
    if [[ "$type" == "flag" ]]; then
      printf "  %-4s %-16s %s\n" "$short," "$long" "$desc"
    else
      if [[ "$req" == "required" ]]; then
        printf "  %-4s %-16s %s (%s) [required]\n" \
          "$short," "$long" "$desc" "$meta"
      else
        printf "  %-4s %-16s %s (%s)\n" \
          "$short," "$long" "$desc" "$meta"
      fi
    fi
  done
  echo "  -h, --help       Show this help and exit"
  echo "  -v, --version    Show version information and exit"
}

# ========= Parse arguments =========
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h | --help)
        argparse_help
        exit 0
        ;;
      -v | --version)
        show_version
        exit 0
        ;;
      --*)
        handled=false
        for spec in "${ARGS[@]}"; do
          IFS='|' read -r type var _ long _ meta _ <<< "$spec"
          if [[ "$1" == "$long" ]]; then
            handled=true
            if [[ "$type" == "flag" ]]; then
              printf -v "$var" true
              shift
            else
              [[ -n "${2:-}" ]] || die "Option $long requires $meta"
              printf -v "$var" "%s" "$2"
              shift 2
            fi
            break
          fi
        done
        $handled || die "Unknown option: $1"
        ;;
      -*)
        handled=false
        for spec in "${ARGS[@]}"; do
          IFS='|' read -r type var short _ _ meta _ <<< "$spec"
          if [[ "$1" == "$short" ]]; then
            handled=true
            if [[ "$type" == "flag" ]]; then
              printf -v "$var" true
              shift
            else
              [[ -n "${2:-}" ]] || die "Option $short requires $meta"
              printf -v "$var" "%s" "$2"
              shift 2
            fi
            break
          fi
        done
        $handled || die "Unknown option: $1"
        ;;
      *)
        POSITIONAL+=("$1")
        shift
        ;;
    esac
  done

  # ========= Check required options =========
  for spec in "${ARGS[@]}"; do
    IFS='|' read -r type var _ long _ _ req <<< "$spec"
    if [[ "$req" == "required" ]]; then
      [[ -n "${!var:-}" ]] || die "Required option missing: $long"
    fi
  done
}

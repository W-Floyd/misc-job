#
# Example customize.py file for j2cli
# Contains potional hooks that modify the way j2cli is initialized


def j2_environment_params():
    """ Extra parameters for the Jinja2 Environment """
    # Jinja2 Environment configuration
    # http://jinja.pocoo.org/docs/2.10/api/#jinja2.Environment
    return dict(
        block_start_string='\\jblock{',
        block_end_string='}',
        variable_start_string='\\jvar{',
        variable_end_string='}',
        comment_start_string='\\#{',
        comment_end_string='}',
        line_statement_prefix='%%',
        line_comment_prefix='%#',
        trim_blocks=True,
        autoescape=False
    )

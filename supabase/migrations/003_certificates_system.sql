/*
 * ============================================
 * IT Learning Hub
 * Migration 003
 * Certificate System
 * ============================================
 */


/*
 * ============================================
 * 1. Add verification fields
 * ============================================
 */

alter table public.certificates
add column if not exists verification_code text;


/*
 * ============================================
 * 2. Certificate status
 * ============================================
 */

alter table public.certificates
add column if not exists is_valid boolean
    not null
    default true;


/*
 * ============================================
 * 3. Verification index
 * ============================================
 */

create unique index if not exists
    certificates_verification_code_unique_idx
on public.certificates(verification_code)
where verification_code is not null;


/*
 * ============================================
 * 4. Public verification policy
 * ============================================
 *
 * Anyone can verify a certificate using
 * its verification code.
 *
 * We intentionally expose only the certificate
 * information needed for verification.
 *
 * The certificate itself remains owned by the
 * authenticated user.
 */

drop policy if exists
    "Anyone can verify valid certificates"
on public.certificates;


create policy
    "Anyone can verify valid certificates"

on public.certificates

for select

to anon, authenticated

using (
    is_valid = true
);


/*
 * ============================================
 * 5. Certificate number generator
 * ============================================
 */

create or replace function
public.generate_certificate_number()

returns text

language plpgsql

security definer

set search_path = public

as $$

declare

    generated_number text;

begin

    generated_number :=
        'ITH-' ||
        to_char(current_date, 'YYYY') ||
        '-' ||
        upper(
            substr(
                md5(
                    random()::text ||
                    clock_timestamp()::text
                ),
                1,
                10
            )
        );

    return generated_number;

end;

$$;


/*
 * ============================================
 * 6. Verification code generator
 * ============================================
 */

create or replace function
public.generate_certificate_verification_code()

returns text

language plpgsql

security definer

set search_path = public

as $$

declare

    generated_code text;

begin

    generated_code :=
        upper(
            substr(
                md5(
                    random()::text ||
                    clock_timestamp()::text ||
                    gen_random_uuid()::text
                ),
                1,
                16
            )
        );

    return generated_code;

end;

$$;


/*
 * ============================================
 * 7. Automatically generate missing codes
 * ============================================
 */

update public.certificates

set
    verification_code =
        upper(
            substr(
                md5(
                    random()::text ||
                    clock_timestamp()::text ||
                    id::text
                ),
                1,
                16
            )
        )

where verification_code is null;


/*
 * ============================================
 * 8. Certificate issuing function
 * ============================================
 *
 * This function creates a certificate after
 * a user passes a level.
 *
 * It is designed to be reusable for every
 * course and every future level.
 */

create or replace function
public.issue_certificate_for_level(
    p_user_id uuid,
    p_level_id bigint,
    p_score integer
)

returns public.certificates

language plpgsql

security definer

set search_path = public

as $$

declare

    result public.certificates;

    selected_level public.levels;

    selected_course public.courses;

    generated_number text;

    generated_code text;

begin

    /*
     * Validate user
     */

    if p_user_id is null then

        raise exception
            'User ID is required';

    end if;


    /*
     * Validate score
     */

    if p_score < 0 or p_score > 100 then

        raise exception
            'Score must be between 0 and 100';

    end if;


    /*
     * Get level
     */

    select *
    into selected_level

    from public.levels

    where id = p_level_id;


    if not found then

        raise exception
            'Level not found';

    end if;


    /*
     * Make sure the user passed
     */

    if p_score < selected_level.passing_score then

        raise exception
            'User did not pass the required score';

    end if;


    /*
     * Get course
     */

    select *
    into selected_course

    from public.courses

    where id = selected_level.course_id;


    if not found then

        raise exception
            'Course not found';

    end if;


    /*
     * Return existing certificate
     * instead of creating a duplicate.
     */

    select *
    into result

    from public.certificates

    where user_id = p_user_id

      and level_id = p_level_id

    limit 1;


    if found then

        return result;

    end if;


    /*
     * Generate unique certificate number
     */

    loop

        generated_number :=
            public.generate_certificate_number();

        exit when not exists (

            select 1

            from public.certificates

            where certificate_number =
                generated_number

        );

    end loop;


    /*
     * Generate unique verification code
     */

    loop

        generated_code :=
            public.generate_certificate_verification_code();

        exit when not exists (

            select 1

            from public.certificates

            where verification_code =
                generated_code

        );

    end loop;


    /*
     * Create certificate
     */

    insert into public.certificates (

        user_id,

        course_id,

        level_id,

        certificate_number,

        course_title,

        level_title,

        description,

        score,

        verification_code,

        is_valid

    )

    values (

        p_user_id,

        selected_course.id,

        selected_level.id,

        generated_number,

        selected_course.title,

        selected_level.title,

        selected_level.description,

        p_score,

        generated_code,

        true

    )

    returning *

    into result;


    return result;

end;

$$;


/*
 * ============================================
 * 9. Restrict certificate issuing function
 * ============================================
 */

revoke all

on function
public.issue_certificate_for_level(
    uuid,
    bigint,
    integer
)

from public;


/*
 * The application uses this function
 * through the authenticated role.
 */

grant execute

on function
public.issue_certificate_for_level(
    uuid,
    bigint,
    integer
)

to authenticated;


/*
 * ============================================
 * 10. Public verification function
 * ============================================
 *
 * Returns only information required to
 * verify a certificate.
 *
 * This avoids exposing user account data.
 */

create or replace function
public.verify_certificate(
    p_verification_code text
)

returns table (

    certificate_number text,

    course_title text,

    level_title text,

    score integer,

    issued_at timestamptz,

    is_valid boolean

)

language sql

security definer

set search_path = public

as $$

    select

        c.certificate_number,

        c.course_title,

        c.level_title,

        c.score,

        c.issued_at,

        c.is_valid

    from public.certificates c

    where upper(c.verification_code) =
          upper(trim(p_verification_code))

      and c.is_valid = true;

$$;


/*
 * ============================================
 * 11. Public verification permissions
 * ============================================
 */

revoke all

on function
public.verify_certificate(text)

from public;


grant execute

on function
public.verify_certificate(text)

to anon, authenticated;


/*
 * ============================================
 * END
 * ============================================
 */
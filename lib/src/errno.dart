// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum ERNO {
  // ignore: unused_field
  _DUMMY,
  EPERM,
  ENOENT,
  ESRCH,
  EINTR,
  EIO,
  ENXIO,
  E2BIG,
  ENOEXEC,
  EBADF,
  ECHILD,
  EAGAIN,
  ENOMEM,
  EACCES,
  EFAULT,
  ENOTBLK,
  EBUSY,
  EEXIST,
  EXDEV,
  ENODEV,
  ENOTDIR,
  EISDIR,
  EINVAL,
  ENFILE,
  EMFILE,
  ENOTTY,
  ETXTBSY,
  EFBIG,
  ENOSPC,
  ESPIPE,
  EROFS,
  EMLINK,
  EPIPE,
  EDOM,
  ERANGE,
  EDEADLK,
  ENAMETOOLONG,
  ENOLCK,
  ENOSYS,
  ENOTEMPTY,
  ELOOP,
  EWOULDBLOCK,
  ENOMSG,
  EIDRM,
  ECHRNG,
  EL2NSYNC,
  EL3HLT,
  EL3RST,
  ELNRNG,
  EUNATCH,
  ENOCSI,
  EL2HLT,
  EBADE,
  EBADR,
  EXFULL,
  ENOANO,
  EBADRQC,
  EBADSLT,
  EDEADLOCK,
  EBFONT,
  ENOSTR,
  ENODATA,
  ETIME,
  ENOSR,
  ENONET,
  ENOPKG,
  EREMOTE,
  ENOLINK,
  EADV,
  ESRMNT,
  ECOMM,
  EPROTO,
  EMULTIHOP,
  EDOTDOT,
  EBADMSG,
  EOVERFLOW,
  ENOTUNIQ,
  EBADFD,
  EREMCHG,
  ELIBACC,
  ELIBBAD,
  ELIBSCN,
  ELIBMAX,
  ELIBEXEC,
  EILSEQ,
  ERESTART,
  ESTRPIPE,
  EUSERS,
  ENOTSOCK,
  EDESTADDRREQ,
  EMSGSIZE,
  EPROTOTYPE,
  ENOPROTOOPT,
  EPROTONOSUPPORT,
  ESOCKTNOSUPPORT,
  EOPNOTSUPP,
  EPFNOSUPPORT,
  EAFNOSUPPORT,
  EADDRINUSE,
  EADDRNOTAVAIL,
  ENETDOWN,
  ENETUNREACH,
  ENETRESET,
  ECONNABORTED,
  ECONNRESET,
  ENOBUFS,
  EISCONN,
  ENOTCONN,
  ESHUTDOWN,
  ETOOMANYREFS,
  ETIMEDOUT,
  ECONNREFUSED,
  EHOSTDOWN,
  EHOSTUNREACH,
  EALREADY,
  EINPROGRESS,
  ESTALE,
  EUCLEAN,
  ENOTNAM,
  ENAVAIL,
  EISNAM,
  EREMOTEIO
}

final _list = <Errno>[
  Errno(ERNO.EPERM, ' Operation not permitted'),
  Errno(ERNO.ENOENT, ' No such file or directory'),
  Errno(ERNO.ESRCH, ' No such process'),
  Errno(ERNO.EINTR, ' Interrupted system call'),
  Errno(ERNO.EIO, ' I/O error'),
  Errno(ERNO.ENXIO, ' No such device or address'),
  Errno(ERNO.E2BIG, ' Arg list too long'),
  Errno(ERNO.ENOEXEC, ' Exec format error'),
  Errno(ERNO.EBADF, ' Bad file number'),
  Errno(ERNO.ECHILD, ' No child processes'),
  Errno(ERNO.EAGAIN, ' Try again'),
  Errno(ERNO.ENOMEM, ' Out of memory'),
  Errno(ERNO.EACCES, ' Permission denied'),
  Errno(ERNO.EFAULT, ' Bad address'),
  Errno(ERNO.ENOTBLK, ' Block device required'),
  Errno(ERNO.EBUSY, ' Device or resource busy'),
  Errno(ERNO.EEXIST, ' File exists'),
  Errno(ERNO.EXDEV, ' Cross-device link'),
  Errno(ERNO.ENODEV, ' No such device'),
  Errno(ERNO.ENOTDIR, ' Not a directory'),
  Errno(ERNO.EISDIR, ' Is a directory'),
  Errno(ERNO.EINVAL, ' Invalid argument'),
  Errno(ERNO.ENFILE, ' File table overflow'),
  Errno(ERNO.EMFILE, ' Too many open files'),
  Errno(ERNO.ENOTTY, ' Not a typewriter'),
  Errno(ERNO.ETXTBSY, ' Text file busy'),
  Errno(ERNO.EFBIG, ' File too large'),
  Errno(ERNO.ENOSPC, ' No space left on device'),
  Errno(ERNO.ESPIPE, ' Illegal seek'),
  Errno(ERNO.EROFS, ' Read-only file system'),
  Errno(ERNO.EMLINK, ' Too many links'),
  Errno(ERNO.EPIPE, ' Broken pipe'),
  Errno(ERNO.EDOM, ' Math argument out of domain of func'),
  Errno(ERNO.ERANGE, ' Math result not representable'),
  Errno(ERNO.EDEADLK, ' Resource deadlock would occur'),
  Errno(ERNO.ENAMETOOLONG, ' File name too long'),
  Errno(ERNO.ENOLCK, ' No record locks available'),
  Errno(ERNO.ENOSYS, ' Function not implemented'),
  Errno(ERNO.ENOTEMPTY, ' Directory not empty'),
  Errno(ERNO.ELOOP, ' Too many symbolic links encountered'),
  Errno(ERNO.EWOULDBLOCK, ' Operation would block'),
  Errno(ERNO.ENOMSG, ' No message of desired type'),
  Errno(ERNO.EIDRM, ' Identifier removed'),
  Errno(ERNO.ECHRNG, ' Channel number out of range'),
  Errno(ERNO.EL2NSYNC, ' Level  not synchronized'),
  Errno(ERNO.EL3HLT, ' Level  halted'),
  Errno(ERNO.EL3RST, ' Level  reset'),
  Errno(ERNO.ELNRNG, ' Link number out of range'),
  Errno(ERNO.EUNATCH, ' Protocol driver not attached'),
  Errno(ERNO.ENOCSI, ' No CSI structure available'),
  Errno(ERNO.EL2HLT, ' Level  halted'),
  Errno(ERNO.EBADE, ' Invalid exchange'),
  Errno(ERNO.EBADR, ' Invalid request descriptor'),
  Errno(ERNO.EXFULL, ' Exchange full'),
  Errno(ERNO.ENOANO, ' No anode'),
  Errno(ERNO.EBADRQC, ' Invalid request code'),
  Errno(ERNO.EBADSLT, ' Invalid slot'),
  Errno(ERNO.EDEADLOCK, ' File locking deadlock error'),
  Errno(ERNO.EBFONT, ' Bad font file format'),
  Errno(ERNO.ENOSTR, ' Device not a stream'),
  Errno(ERNO.ENODATA, ' No data available'),
  Errno(ERNO.ETIME, ' Timer expired'),
  Errno(ERNO.ENOSR, ' Out of streams resources'),
  Errno(ERNO.ENONET, ' Machine is not on the network'),
  Errno(ERNO.ENOPKG, ' Package not installed'),
  Errno(ERNO.EREMOTE, ' Object is remote'),
  Errno(ERNO.ENOLINK, ' Link has been severed'),
  Errno(ERNO.EADV, ' Advertise error'),
  Errno(ERNO.ESRMNT, ' Srmount error'),
  Errno(ERNO.ECOMM, ' Communication error on send'),
  Errno(ERNO.EPROTO, ' Protocol error'),
  Errno(ERNO.EMULTIHOP, ' Multihop attempted'),
  Errno(ERNO.EDOTDOT, ' RFS specific error'),
  Errno(ERNO.EBADMSG, ' Not a data message'),
  Errno(ERNO.EOVERFLOW, ' Value too large for defined data type'),
  Errno(ERNO.ENOTUNIQ, ' Name not unique on network'),
  Errno(ERNO.EBADFD, ' File descriptor in bad state'),
  Errno(ERNO.EREMCHG, ' Remote address changed'),
  Errno(ERNO.ELIBACC, ' Can not access a needed shared library'),
  Errno(ERNO.ELIBBAD, ' Accessing a corrupted shared library'),
  Errno(ERNO.ELIBSCN, ' .lib section in a.out corrupted'),
  Errno(ERNO.ELIBMAX, ' Attempting to link in too many shared libraries'),
  Errno(ERNO.ELIBEXEC, ' Cannot exec a shared library directly'),
  Errno(ERNO.EILSEQ, ' Illegal byte sequence'),
  Errno(ERNO.ERESTART, ' Interrupted system call should be restarted'),
  Errno(ERNO.ESTRPIPE, ' Streams pipe error'),
  Errno(ERNO.EUSERS, ' Too many users'),
  Errno(ERNO.ENOTSOCK, ' Socket operation on non-socket'),
  Errno(ERNO.EDESTADDRREQ, ' Destination address required'),
  Errno(ERNO.EMSGSIZE, ' Message too long'),
  Errno(ERNO.EPROTOTYPE, ' Protocol wrong type for socket'),
  Errno(ERNO.ENOPROTOOPT, ' Protocol not available'),
  Errno(ERNO.EPROTONOSUPPORT, ' Protocol not supported'),
  Errno(ERNO.ESOCKTNOSUPPORT, ' Socket type not supported'),
  Errno(ERNO.EOPNOTSUPP, ' Operation not supported on transport endpoint'),
  Errno(ERNO.EPFNOSUPPORT, ' Protocol family not supported'),
  Errno(ERNO.EAFNOSUPPORT, ' Address family not supported by protocol'),
  Errno(ERNO.EADDRINUSE, ' Address already in use'),
  Errno(ERNO.EADDRNOTAVAIL, ' Cannot assign requested address'),
  Errno(ERNO.ENETDOWN, ' Network is down'),
  Errno(ERNO.ENETUNREACH, ' Network is unreachable'),
  Errno(ERNO.ENETRESET, ' Network dropped connection because of reset'),
  Errno(ERNO.ECONNABORTED, ' Software caused connection abort'),
  Errno(ERNO.ECONNRESET, ' Connection reset by peer'),
  Errno(ERNO.ENOBUFS, ' No buffer space available'),
  Errno(ERNO.EISCONN, ' Transport endpoint is already connected'),
  Errno(ERNO.ENOTCONN, ' Transport endpoint is not connected'),
  Errno(ERNO.ESHUTDOWN, ' Cannot send after transport endpoint shutdown'),
  Errno(ERNO.ETOOMANYREFS, ' Too many references: cannot splice'),
  Errno(ERNO.ETIMEDOUT, ' Connection timed out'),
  Errno(ERNO.ECONNREFUSED, ' Connection refused'),
  Errno(ERNO.EHOSTDOWN, ' Host is down'),
  Errno(ERNO.EHOSTUNREACH, ' No route to host'),
  Errno(ERNO.EALREADY, ' Operation already in progress'),
  Errno(ERNO.EINPROGRESS, ' Operation now in progress'),
  Errno(ERNO.ESTALE, ' Stale NFS file handle'),
  Errno(ERNO.EUCLEAN, ' Structure needs cleaning'),
  Errno(ERNO.ENOTNAM, ' Not a XENIX named type file'),
  Errno(ERNO.ENAVAIL, ' No XENIX semaphores available'),
  Errno(ERNO.EISNAM, ' Is a named type file'),
  Errno(ERNO.EREMOTEIO, ' Remote I/O error')
];

class ErrnoNotFound implements Exception {
  final String errorMsg;
  ErrnoNotFound(this.errorMsg);
  @override
  String toString() => errorMsg;
}

class Errno {
  final ERNO erno;
  final String description;

  Errno(this.erno, this.description);

  static Errno findByName(String name) {
    for (var e in _list) {
      if (e.erno.toString() == name) {
        return e;
      }
    }
    throw ErrnoNotFound('Erno with name \'$name\' not found!');
  }

  static Errno findByEnum(ERNO erno) {
    return _list[erno.index];
  }

  static Errno findByErno(int erno) {
    if (erno < 1 || erno >= _list.length) {
      throw ErrnoNotFound('Erno with number $erno not found!');
    }
    return _list[erno];
  }
}  


/*

#define	EPERM		 1	/* Operation not permitted */
#define	ENOENT		 2	/* No such file or directory */
#define	ESRCH		 3	/* No such process */
#define	EINTR		 4	/* Interrupted system call */
#define	EIO		 5	/* I/O error */
#define	ENXIO		 6	/* No such device or address */
#define	E2BIG		 7	/* Arg list too long */
#define	ENOEXEC		 8	/* Exec format error */
#define	EBADF		 9	/* Bad file number */
#define	ECHILD		10	/* No child processes */
#define	EAGAIN		11	/* Try again */
#define	ENOMEM		12	/* Out of memory */
#define	EACCES		13	/* Permission denied */
#define	EFAULT		14	/* Bad address */
#define	ENOTBLK		15	/* Block device required */
#define	EBUSY		16	/* Device or resource busy */
#define	EEXIST		17	/* File exists */
#define	EXDEV		18	/* Cross-device link */
#define	ENODEV		19	/* No such device */
#define	ENOTDIR		20	/* Not a directory */
#define	EISDIR		21	/* Is a directory */
#define	EINVAL		22	/* Invalid argument */
#define	ENFILE		23	/* File table overflow */
#define	EMFILE		24	/* Too many open files */
#define	ENOTTY		25	/* Not a typewriter */
#define	ETXTBSY		26	/* Text file busy */
#define	EFBIG		27	/* File too large */
#define	ENOSPC		28	/* No space left on device */
#define	ESPIPE		29	/* Illegal seek */
#define	EROFS		30	/* Read-only file system */
#define	EMLINK		31	/* Too many links */
#define	EPIPE		32	/* Broken pipe */
#define	EDOM		33	/* Math argument out of domain of func */
#define	ERANGE		34	/* Math result not representable */
#define	EDEADLK		35	/* Resource deadlock would occur */
#define	ENAMETOOLONG	36	/* File name too long */
#define	ENOLCK		37	/* No record locks available */
#define	ENOSYS		38	/* Function not implemented */
#define	ENOTEMPTY	39	/* Directory not empty */
#define	ELOOP		40	/* Too many symbolic links encountered */
#define	EWOULDBLOCK	41	/* Operation would block */
#define	ENOMSG		42	/* No message of desired type */
#define	EIDRM		43	/* Identifier removed */
#define	ECHRNG		44	/* Channel number out of range */
#define	EL2NSYNC	45	/* Level 2 not synchronized */
#define	EL3HLT		46	/* Level 3 halted */
#define	EL3RST		47	/* Level 3 reset */
#define	ELNRNG		48	/* Link number out of range */
#define	EUNATCH		49	/* Protocol driver not attached */
#define	ENOCSI		50	/* No CSI structure available */
#define	EL2HLT		51	/* Level 2 halted */
#define	EBADE		52	/* Invalid exchange */
#define	EBADR		53	/* Invalid request descriptor */
#define	EXFULL		54	/* Exchange full */
#define	ENOANO		55	/* No anode */
#define	EBADRQC		56	/* Invalid request code */
#define	EBADSLT		57	/* Invalid slot */
#define	EDEADLOCK	58	/* File locking deadlock error */
#define	EBFONT		59	/* Bad font file format */
#define	ENOSTR		60	/* Device not a stream */
#define	ENODATA		61	/* No data available */
#define	ETIME		62	/* Timer expired */
#define	ENOSR		63	/* Out of streams resources */
#define	ENONET		64	/* Machine is not on the network */
#define	ENOPKG		65	/* Package not installed */
#define	EREMOTE		66	/* Object is remote */
#define	ENOLINK		67	/* Link has been severed */
#define	EADV		68	/* Advertise error */
#define	ESRMNT		69	/* Srmount error */
#define	ECOMM		70	/* Communication error on send */
#define	EPROTO		71	/* Protocol error */
#define	EMULTIHOP	72	/* Multihop attempted */
#define	EDOTDOT		73	/* RFS specific error */
#define	EBADMSG		74	/* Not a data message */
#define	EOVERFLOW	75	/* Value too large for defined data type */
#define	ENOTUNIQ	76	/* Name not unique on network */
#define	EBADFD		77	/* File descriptor in bad state */
#define	EREMCHG		78	/* Remote address changed */
#define	ELIBACC		79	/* Can not access a needed shared library */
#define	ELIBBAD		80	/* Accessing a corrupted shared library */
#define	ELIBSCN		81	/* .lib section in a.out corrupted */
#define	ELIBMAX		82	/* Attempting to link in too many shared libraries */
#define	ELIBEXEC	83	/* Cannot exec a shared library directly */
#define	EILSEQ		84	/* Illegal byte sequence */
#define	ERESTART	85	/* Interrupted system call should be restarted */
#define	ESTRPIPE	86	/* Streams pipe error */
#define	EUSERS		87	/* Too many users */
#define	ENOTSOCK	88	/* Socket operation on non-socket */
#define	EDESTADDRREQ	89	/* Destination address required */
#define	EMSGSIZE	90	/* Message too long */
#define	EPROTOTYPE	91	/* Protocol wrong type for socket */
#define	ENOPROTOOPT	92	/* Protocol not available */
#define	EPROTONOSUPPORT	93	/* Protocol not supported */
#define	ESOCKTNOSUPPORT	94	/* Socket type not supported */
#define	EOPNOTSUPP	95	/* Operation not supported on transport endpoint */
#define	EPFNOSUPPORT	96	/* Protocol family not supported */
#define	EAFNOSUPPORT	97	/* Address family not supported by protocol */
#define	EADDRINUSE	98	/* Address already in use */
#define	EADDRNOTAVAIL	99	/* Cannot assign requested address */
#define	ENETDOWN	100	/* Network is down */
#define	ENETUNREACH	101	/* Network is unreachable */
#define	ENETRESET	102	/* Network dropped connection because of reset */
#define	ECONNABORTED	103	/* Software caused connection abort */
#define	ECONNRESET	104	/* Connection reset by peer */
#define	ENOBUFS		105	/* No buffer space available */
#define	EISCONN		106	/* Transport endpoint is already connected */
#define	ENOTCONN	107	/* Transport endpoint is not connected */
#define	ESHUTDOWN	108	/* Cannot send after transport endpoint shutdown */
#define	ETOOMANYREFS	109	/* Too many references: cannot splice */
#define	ETIMEDOUT	110	/* Connection timed out */
#define	ECONNREFUSED	111	/* Connection refused */
#define	EHOSTDOWN	112	/* Host is down */
#define	EHOSTUNREACH	113	/* No route to host */
#define	EALREADY	114	/* Operation already in progress */
#define	EINPROGRESS	115	/* Operation now in progress */
#define	ESTALE		116	/* Stale NFS file handle */
#define	EUCLEAN		117	/* Structure needs cleaning */
#define	ENOTNAM		118	/* Not a XENIX named type file */
#define	ENAVAIL		119	/* No XENIX semaphores available */
#define	EISNAM		120	/* Is a named type file */
#define	EREMOTEIO	121	/* Remote I/O error */
*/
// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

/// Dart enum representation of the Linux errno.h defintions.
enum ERRNO {
  // ignore: unused_field
  _dummy,
  eperm,
  enoent,
  esrch,
  eintr,
  eio,
  enxio,
  e2big,
  enoexec,
  ebadf,
  echild,
  eagain,
  enomem,
  eacces,
  efault,
  enotblk,
  ebusy,
  eexist,
  exdev,
  enodev,
  enotdir,
  eisdir,
  einval,
  enfile,
  emfile,
  enotty,
  etxtbsy,
  efbig,
  enospc,
  espipe,
  erofs,
  emlink,
  epipe,
  edom,
  erange,
  edeadlk,
  enametoolong,
  enolck,
  enosys,
  enotempty,
  eloop,
  ewouldblock,
  enomsg,
  eidrm,
  echrng,
  el2nsync,
  el3hlt,
  el3rst,
  elnrng,
  eunatch,
  enocsi,
  el2hlt,
  ebade,
  ebadr,
  exfull,
  enoano,
  ebadrqc,
  ebadslt,
  edeadlock,
  ebfont,
  enostr,
  enodata,
  etime,
  enosr,
  enonet,
  enopkg,
  eremote,
  enolink,
  eadv,
  esrmnt,
  ecomm,
  eproto,
  emultihop,
  edotdot,
  ebadmsg,
  eoverflow,
  enotuniq,
  ebadfd,
  eremchg,
  elibacc,
  elibbad,
  elibscn,
  elibmax,
  elibexec,
  eilseq,
  erestart,
  estrpipe,
  eusers,
  enotsock,
  edestaddrreq,
  emsgsize,
  eprototype,
  enoprotoopt,
  eprotonosupport,
  esocktnosupport,
  eopnotsupp,
  epfnosupport,
  eafnosupport,
  eaddrinuse,
  eaddrnotavail,
  enetdown,
  enetunreach,
  enetreset,
  econnaborted,
  econnreset,
  enobufs,
  eisconn,
  enotconn,
  eshutdown,
  etoomanyrefs,
  etimedout,
  econnrefused,
  ehostdown,
  ehostunreach,
  ealready,
  einprogress,
  estale,
  euclean,
  enotnam,
  enavail,
  eisnam,
  eremoteio
}

final _list = <Errno>[
  Errno(ERRNO.eperm, ' Operation not permitted'),
  Errno(ERRNO.enoent, ' No such file or directory'),
  Errno(ERRNO.esrch, ' No such process'),
  Errno(ERRNO.eintr, ' Interrupted system call'),
  Errno(ERRNO.eio, ' I/O error'),
  Errno(ERRNO.enxio, ' No such device or address'),
  Errno(ERRNO.e2big, ' Arg list too long'),
  Errno(ERRNO.enoexec, ' Exec format error'),
  Errno(ERRNO.ebadf, ' Bad file number'),
  Errno(ERRNO.echild, ' No child processes'),
  Errno(ERRNO.eagain, ' Try again'),
  Errno(ERRNO.enomem, ' Out of memory'),
  Errno(ERRNO.eacces, ' Permission denied'),
  Errno(ERRNO.efault, ' Bad address'),
  Errno(ERRNO.enotblk, ' Block device required'),
  Errno(ERRNO.ebusy, ' Device or resource busy'),
  Errno(ERRNO.eexist, ' File exists'),
  Errno(ERRNO.exdev, ' Cross-device link'),
  Errno(ERRNO.enodev, ' No such device'),
  Errno(ERRNO.enotdir, ' Not a directory'),
  Errno(ERRNO.eisdir, ' Is a directory'),
  Errno(ERRNO.einval, ' Invalid argument'),
  Errno(ERRNO.enfile, ' File table overflow'),
  Errno(ERRNO.emfile, ' Too many open files'),
  Errno(ERRNO.enotty, ' Not a typewriter'),
  Errno(ERRNO.etxtbsy, ' Text file busy'),
  Errno(ERRNO.efbig, ' File too large'),
  Errno(ERRNO.enospc, ' No space left on device'),
  Errno(ERRNO.espipe, ' Illegal seek'),
  Errno(ERRNO.erofs, ' Read-only file system'),
  Errno(ERRNO.emlink, ' Too many links'),
  Errno(ERRNO.epipe, ' Broken pipe'),
  Errno(ERRNO.edom, ' Math argument out of domain of func'),
  Errno(ERRNO.erange, ' Math result not representable'),
  Errno(ERRNO.edeadlk, ' Resource deadlock would occur'),
  Errno(ERRNO.enametoolong, ' File name too long'),
  Errno(ERRNO.enolck, ' No record locks available'),
  Errno(ERRNO.enosys, ' Function not implemented'),
  Errno(ERRNO.enotempty, ' Directory not empty'),
  Errno(ERRNO.eloop, ' Too many symbolic links encountered'),
  Errno(ERRNO.ewouldblock, ' Operation would block'),
  Errno(ERRNO.enomsg, ' No message of desired type'),
  Errno(ERRNO.eidrm, ' Identifier removed'),
  Errno(ERRNO.echrng, ' Channel number out of range'),
  Errno(ERRNO.el2nsync, ' Level  not synchronized'),
  Errno(ERRNO.el3hlt, ' Level  halted'),
  Errno(ERRNO.el3rst, ' Level  reset'),
  Errno(ERRNO.elnrng, ' Link number out of range'),
  Errno(ERRNO.eunatch, ' Protocol driver not attached'),
  Errno(ERRNO.enocsi, ' No CSI structure available'),
  Errno(ERRNO.el2hlt, ' Level  halted'),
  Errno(ERRNO.ebade, ' Invalid exchange'),
  Errno(ERRNO.ebadr, ' Invalid request descriptor'),
  Errno(ERRNO.exfull, ' Exchange full'),
  Errno(ERRNO.enoano, ' No anode'),
  Errno(ERRNO.ebadrqc, ' Invalid request code'),
  Errno(ERRNO.ebadslt, ' Invalid slot'),
  Errno(ERRNO.edeadlock, ' File locking deadlock error'),
  Errno(ERRNO.ebfont, ' Bad font file format'),
  Errno(ERRNO.enostr, ' Device not a stream'),
  Errno(ERRNO.enodata, ' No data available'),
  Errno(ERRNO.etime, ' Timer expired'),
  Errno(ERRNO.enosr, ' Out of streams resources'),
  Errno(ERRNO.enonet, ' Machine is not on the network'),
  Errno(ERRNO.enopkg, ' Package not installed'),
  Errno(ERRNO.eremote, ' Object is remote'),
  Errno(ERRNO.enolink, ' Link has been severed'),
  Errno(ERRNO.eadv, ' Advertise error'),
  Errno(ERRNO.esrmnt, ' Srmount error'),
  Errno(ERRNO.ecomm, ' Communication error on send'),
  Errno(ERRNO.eproto, ' Protocol error'),
  Errno(ERRNO.emultihop, ' Multihop attempted'),
  Errno(ERRNO.edotdot, ' RFS specific error'),
  Errno(ERRNO.ebadmsg, ' Not a data message'),
  Errno(ERRNO.eoverflow, ' Value too large for defined data type'),
  Errno(ERRNO.enotuniq, ' Name not unique on network'),
  Errno(ERRNO.ebadfd, ' File descriptor in bad state'),
  Errno(ERRNO.eremchg, ' Remote address changed'),
  Errno(ERRNO.elibacc, ' Can not access a needed shared library'),
  Errno(ERRNO.elibbad, ' Accessing a corrupted shared library'),
  Errno(ERRNO.elibscn, ' .lib section in a.out corrupted'),
  Errno(ERRNO.elibmax, ' Attempting to link in too many shared libraries'),
  Errno(ERRNO.elibexec, ' Cannot exec a shared library directly'),
  Errno(ERRNO.eilseq, ' Illegal byte sequence'),
  Errno(ERRNO.erestart, ' Interrupted system call should be restarted'),
  Errno(ERRNO.estrpipe, ' Streams pipe error'),
  Errno(ERRNO.eusers, ' Too many users'),
  Errno(ERRNO.enotsock, ' Socket operation on non-socket'),
  Errno(ERRNO.edestaddrreq, ' Destination address required'),
  Errno(ERRNO.emsgsize, ' Message too long'),
  Errno(ERRNO.eprototype, ' Protocol wrong type for socket'),
  Errno(ERRNO.enoprotoopt, ' Protocol not available'),
  Errno(ERRNO.eprotonosupport, ' Protocol not supported'),
  Errno(ERRNO.esocktnosupport, ' Socket type not supported'),
  Errno(ERRNO.eopnotsupp, ' Operation not supported on transport endpoint'),
  Errno(ERRNO.epfnosupport, ' Protocol family not supported'),
  Errno(ERRNO.eafnosupport, ' Address family not supported by protocol'),
  Errno(ERRNO.eaddrinuse, ' Address already in use'),
  Errno(ERRNO.eaddrnotavail, ' Cannot assign requested address'),
  Errno(ERRNO.enetdown, ' Network is down'),
  Errno(ERRNO.enetunreach, ' Network is unreachable'),
  Errno(ERRNO.enetreset, ' Network dropped connection because of reset'),
  Errno(ERRNO.econnaborted, ' Software caused connection abort'),
  Errno(ERRNO.econnreset, ' Connection reset by peer'),
  Errno(ERRNO.enobufs, ' No buffer space available'),
  Errno(ERRNO.eisconn, ' Transport endpoint is already connected'),
  Errno(ERRNO.enotconn, ' Transport endpoint is not connected'),
  Errno(ERRNO.eshutdown, ' Cannot send after transport endpoint shutdown'),
  Errno(ERRNO.etoomanyrefs, ' Too many references: cannot splice'),
  Errno(ERRNO.etimedout, ' Connection timed out'),
  Errno(ERRNO.econnrefused, ' Connection refused'),
  Errno(ERRNO.ehostdown, ' Host is down'),
  Errno(ERRNO.ehostunreach, ' No route to host'),
  Errno(ERRNO.ealready, ' Operation already in progress'),
  Errno(ERRNO.einprogress, ' Operation now in progress'),
  Errno(ERRNO.estale, ' Stale NFS file handle'),
  Errno(ERRNO.euclean, ' Structure needs cleaning'),
  Errno(ERRNO.enotnam, ' Not a XENIX named type file'),
  Errno(ERRNO.enavail, ' No XENIX semaphores available'),
  Errno(ERRNO.eisnam, ' Is a named type file'),
  Errno(ERRNO.eremoteio, ' Remote I/O error')
];

/// Exception
class ErrnoNotFound implements Exception {
  final String errorMsg;
  ErrnoNotFound(this.errorMsg);
  @override
  String toString() => errorMsg;
}

/// Helper class for Linux errno.h definitions.
class Errno {
  final ERRNO erno;
  final String description;

  Errno(this.erno, this.description);

  // Gets Errno by name.
  static Errno findByName(String name) {
    for (var e in _list) {
      if (e.erno.toString() == name) {
        return e;
      }
    }
    throw ErrnoNotFound('Errno with name \'$name\' not found!');
  }

  // Gets Errno by enum.
  static Errno findByEnum(ERRNO errno) {
    return _list[errno.index];
  }

  // Gets Errno by int index.
  static Errno findByErno(int errno) {
    if (errno < 1 || errno >= _list.length) {
      throw ErrnoNotFound('Errno with number $errno not found!');
    }
    return _list[errno];
  }
}
